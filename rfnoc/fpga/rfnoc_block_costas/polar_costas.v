module polar_costas (
  input aclk,
  input aresetn,

  input signed [15:0] s_axis_i_tdata,
  input               s_axis_i_tvalid,
  output              s_axis_i_tready,
  
  input signed [15:0] s_axis_q_tdata,
  input               s_axis_q_tvalid,
  output              s_axis_q_tready,
  
  
  output signed [15:0] m_axis_i_sync_tdata,
  output 		  m_axis_i_sync_tvalid,
  input		  m_axis_i_sync_tready,
  output signed [15:0] m_axis_q_sync_tdata,
  output 		  m_axis_q_sync_tvalid,
  input		  m_axis_q_sync_tready
);

wire [31:0] nco_out_tdata;
wire        nco_out_tvalid;
wire [31:0] mixer_out_tdata;
wire        mixer_out_tvalid;
wire signed [16:0] phase_detect;
wire [23:0] phase_offset_tdata;
wire        phase_offset_tvalid;

// debug
wire [15:0] nco_out_i, nco_out_q;
assign nco_out_q = nco_out_tdata[31:16];
assign nco_out_i = nco_out_tdata[15:0];
// end debug

// 首先是NCO 数控振荡器
nco nco (
  .aclk(aclk),                                // input wire aclk
  .aresetn(aresetn),                          // input wire aresetn
  .s_axis_phase_tvalid(s_axis_i_tvalid),  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata(phase_offset_tdata),    // input wire [23 : 0] s_axis_phase_tdata, phase increment ufix21_21
  .m_axis_data_tvalid(nco_out_tvalid),    // output wire m_axis_data_tvalid
  .m_axis_data_tdata(nco_out_tdata)      // output wire [31 : 0] m_axis_data_tdata  [31:16] sine fix16_15; [15:0]cos fix16_15
);


// 复数乘法器，与NCO相乘 构成混频器
cmpy_0 cmpy (
  .aclk(aclk),                              // input wire aclk
  .aresetn(aresetn),                        // input wire aresetn
  .s_axis_a_tvalid(nco_out_tvalid),        // input wire s_axis_a_tvalid
  .s_axis_a_tdata(nco_out_tdata),          // input wire [31 : 0] s_axis_a_tdata. [31:16] Q(Imag) fix16_0; [15:0] I(Real) fix16_0
  .s_axis_b_tvalid(s_axis_i_tvalid && s_axis_q_tvalid),        // input wire s_axis_b_tvalid
  .s_axis_b_tdata({s_axis_q_tdata, s_axis_i_tdata}),          // input wire [31 : 0] s_axis_b_tdata. [31:16] Q(Imag) fix16_0; [15:0] I(Real) fix16_0
  .m_axis_dout_tvalid(mixer_out_tvalid),  // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(mixer_out_tdata)     // output wire [31 : 0] m_axis_dout_tdata. [31:16] Q(Imag) fix16_0; [15:0] I(Real) fix16_0
);

// 鉴相器
// sign( real(mixer_out) )*imag(mixer_out)  -  sign(imag(mixer_out))*real(mixer_out)
reg signed [15:0] before_LF_plus;
reg signed [15:0] before_LF_minus;
reg               phase_detect_valid;
wire signed [15:0] mixer_out_i;
wire signed [15:0] mixer_out_q;
assign mixer_out_i = mixer_out_tdata[15:0];
assign mixer_out_q = mixer_out_tdata[31:16];
// output module
assign m_axis_i_sync_tdata = mixer_out_i;
assign m_axis_q_sync_tdata = mixer_out_q;
assign m_axis_i_sync_tvalid = mixer_out_tvalid;
assign m_axis_q_sync_tvalid = mixer_out_tvalid;

always @(posedge aclk or negedge aresetn) begin
  if(!aresetn) begin
    before_LF_plus <= 0;
    before_LF_minus <= 0;
    phase_detect_valid <= 0;
  end
  else begin
    phase_detect_valid <= mixer_out_tvalid;   // 一拍延迟
    if (mixer_out_i[15]) begin
      before_LF_plus <= -mixer_out_q;
    end
    else begin
      before_LF_plus <= mixer_out_q;
    end

    if (mixer_out_q[15]) begin
      before_LF_minus <= -mixer_out_i;
    end
    else begin
      before_LF_minus <= mixer_out_i;
    end
  end
end

assign phase_detect = {before_LF_plus[15], before_LF_plus} - {before_LF_minus[15], before_LF_minus};  // [16:0] sfix17_15

wire signed [17:0] loop_filter_out;
wire               loop_filter_out_valid;
// 环路滤波器
loop_filter lp
(
   .rst_n(aresetn),
   .clk(aclk),
   .pd(phase_detect),                // 鉴相器输出 [16:0] sfix17_15
   .pd_valid(phase_detect_valid),
   .dout(loop_filter_out), // loop filter 输出[17:0] sfix18_15
   .dout_valid(loop_filter_out_valid)
);

reg signed [21:0] pacc;   // sfix22_15

// pacc = pacc + loop_filter_out

always @(posedge aclk or negedge aresetn) begin
  if(!aresetn) pacc <= 22'h1;
  else begin
    if(loop_filter_out_valid) pacc <= pacc + loop_filter_out;
    else pacc <= pacc;
  end
end

reg signed [21:0] pacc_abs;  //// sfix22_15

always @(*) begin
  if (pacc[21]) pacc_abs = -pacc;
  else pacc_abs = pacc;
end

// 根据matlab公式， pacc的结果仍然需要 /256 = 2^8. 首先需要将小数点对齐，后补6
// 位0，之后后面舍弃8位，即除256
assign phase_offset_tdata = { {6'b0}, pacc_abs[21:4] };      // [23:0]   ufix21_21
assign phase_offset_tvalid = loop_filter_out_valid;
endmodule
