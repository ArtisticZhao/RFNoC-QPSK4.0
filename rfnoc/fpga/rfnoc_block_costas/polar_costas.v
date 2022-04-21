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
wire [79:0] mixer_out_tdata;// output wire [79 : 0] m_axis_dout_tdata. [31:16] Q(Imag) fix33_30; [15:0] I(Real) fix33_30
wire        mixer_out_tvalid;
wire signed [33:0] phase_detect;
wire [31:0] phase_offset_tdata;
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
  .s_axis_phase_tdata(phase_offset_tdata),    // input wire [31 : 0] s_axis_phase_tdata, phase increment ufix30_30
  .m_axis_data_tvalid(nco_out_tvalid),    // output wire m_axis_data_tvalid
  .m_axis_data_tdata(nco_out_tdata)      // output wire [79 : 0] m_axis_dout_tdata. [72:40] Q(Imag) fix33_30; [32:0] I(Real) fix33_30
);


// 复数乘法器，与NCO相乘 构成混频器
cmpy_0 cmpy (
  .aclk(aclk),                              // input wire aclk
  .aresetn(aresetn),                        // input wire aresetn
  .s_axis_a_tvalid(nco_out_tvalid),        // input wire s_axis_a_tvalid
  .s_axis_a_tdata(nco_out_tdata),          // input wire [31 : 0] s_axis_a_tdata. [31:16] Q(Imag) fix16_15; [15:0] I(Real) fix16_15
  .s_axis_b_tvalid(s_axis_i_tvalid && s_axis_q_tvalid),        // input wire s_axis_b_tvalid
  .s_axis_b_tdata({s_axis_q_tdata, s_axis_i_tdata}),          // input wire [31 : 0] s_axis_b_tdata. [31:16] Q(Imag) fix16_15; [15:0] I(Real) fix16_15
  .m_axis_dout_tvalid(mixer_out_tvalid),  // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(mixer_out_tdata)     // output wire [79 : 0] m_axis_dout_tdata. [72:40] Q(Imag) fix33_30; [32:0] I(Real) fix33_30
);

// 鉴相器
// sign( real(mixer_out) )*imag(mixer_out)  -  sign(imag(mixer_out))*real(mixer_out)
reg signed [32:0] before_LF_plus;
reg signed [32:0] before_LF_minus;
reg               phase_detect_valid;
wire signed [32:0] mixer_out_i;
wire signed [32:0] mixer_out_q;
assign mixer_out_i = mixer_out_tdata[32:0];
assign mixer_out_q = mixer_out_tdata[72:40];
// output module
assign m_axis_i_sync_tdata = mixer_out_i[32:17];
assign m_axis_q_sync_tdata = mixer_out_q[32:17];
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
    if (mixer_out_i[32]) begin
      before_LF_plus <= -mixer_out_q;
    end
    else begin
      before_LF_plus <= mixer_out_q;
    end

    if (mixer_out_q[32]) begin
      before_LF_minus <= -mixer_out_i;
    end
    else begin
      before_LF_minus <= mixer_out_i;
    end
  end
end

assign phase_detect = {before_LF_plus[32], before_LF_plus} - {before_LF_minus[32], before_LF_minus};  // [33:0] sfix34_30

wire signed [34:0] loop_filter_out;
wire               loop_filter_out_valid;
// 环路滤波器
loop_filter lp
(
   .rst_n(aresetn),
   .clk(aclk),
   .pd(phase_detect),                // 鉴相器输出 [33:0] sfix34_30
   .pd_valid(phase_detect_valid),
   .dout(loop_filter_out), // loop filter 输出[34:0] sfix35_30
   .dout_valid(loop_filter_out_valid)
);

// 环路增益 K = 1/256
wire signed [34:0] K_loop_filter;
assign K_loop_filter = { {8{loop_filter_out[34]}}, loop_filter_out[34:8] };  // sfix35_30

reg signed [38:0] pacc;   // sfix35_30

// pacc = pacc + loop_filter_out

always @(posedge aclk or negedge aresetn) begin
  if(!aresetn) pacc <= 39'h1;
  else begin
    if(loop_filter_out_valid) pacc <= pacc + {{4{K_loop_filter[34]}}, K_loop_filter};
    else pacc <= pacc;
  end
end

reg signed [38:0] pacc_abs;  //// sfix35_30

always @(*) begin
  if (pacc[38]) pacc_abs = +pacc;
  else pacc_abs = -pacc;
end

// 首先需要将小数点对齐  nco phase = ufix30_30
// assign phase_offset_tdata = { {2'b0}, pacc_abs[21:0] };      // [23:0]   ufix21_21
assign phase_offset_tdata = { {2'b0}, pacc_abs[29:0] };  // ufix30_30
assign phase_offset_tvalid = loop_filter_out_valid;
endmodule
