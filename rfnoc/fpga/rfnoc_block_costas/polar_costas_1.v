`timescale 1ns / 1ps
module polar_costas(
    input ce_clk,
    input ce_rst,
    
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
    //output signed [31: 0] loopfilter_out  // but nco input phase only 26 bits
);
    assign s_axis_i_tready = 1;
    assign s_axis_q_tready = 1;
    // instance NCO ip core
    wire nco_tvalid;
    wire [31:0] nco_complex_cos_sin;
    wire [31: 0] loopfilter_out;
    nco nco (
        .aclk(ce_clk),                        // input wire aclk
        .aresetn(ce_rst),                     // input wire aresetn
        .s_axis_phase_tvalid(1'b1),           // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata(loopfilter_out),  // input wire [31 : 0] s_axis_phase_tdata
        .m_axis_data_tvalid(nco_tvalid),
        .m_axis_data_tdata(nco_complex_cos_sin)        // output wire [15 : 0] m_axis_data_tdata
    );
    wire [79:0] cmult_m_axis_dout_tdata;
    wire signed [15:0] i_after_nco_s;
    wire signed [15:0] q_after_nco_s;
    // 取高16位 继续计算
    assign q_after_nco_s = cmult_m_axis_dout_tdata[72:57];
    assign i_after_nco_s = cmult_m_axis_dout_tdata[32:17];
    reg signed [15:0] before_LF_plus;
    reg signed [15:0] before_LF_minus;
    wire signed [16:0] pd;
    // A data from i,q  B data from nco
    cmpy_0 cmult_nco (
        .aclk(ce_clk),                              // input wire aclk
        .aresetn(ce_rst),                        // input wire aresetn
        .s_axis_a_tvalid(nco_tvalid),        // input wire s_axis_a_tvalid
        .s_axis_a_tdata({q,i}),          // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(nco_tvalid),        // input wire s_axis_b_tvalid
        .s_axis_b_tdata(nco_complex_cos_sin),          // input wire [31 : 0] s_axis_b_tdata
        // .m_axis_dout_tvalid(m_axis_dout_tvalid),  // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata(cmult_m_axis_dout_tdata)    // output wire [79 : 0] m_axis_dout_tdata
    );

//    wire signed [23:0] i_after_nco = i*cos - q*sin;
//    wire signed [23:0] q_after_nco = q*cos + i*sin;

//    wire sign_i_after_nco;  // 这是i_after_noc的符号, 1为+ 0为-
//    wire sign_q_after_nco;
//    assign sign_i_after_nco = (i_after_nco > 0) ? 1 : 0;
//    assign sign_q_after_nco = (q_after_nco > 0) ? 1 : 0;

//    wire signed [23:0] before_LF_plus = (sign_i_after_nco) ? q_after_nco : -q_after_nco;
//    wire signed [23:0] before_LF_minus = (sign_q_after_nco) ? i_after_nco : -i_after_nco;
    always @ (posedge ce_clk or negedge ce_rst) begin
        if(!ce_rst) begin
            before_LF_plus <= 0;
            before_LF_minus <= 0;
        end
        else begin
            // 鉴相器
            if (i_after_nco_s[15])  // signed数 最高位为符号位, 1为负数  0为正数
                before_LF_plus <= -q_after_nco_s;
            else
                before_LF_plus <= q_after_nco_s;
            if (q_after_nco_s[15])
                before_LF_minus <= -i_after_nco_s;
            else
                before_LF_minus <= i_after_nco_s;
        end
    end
    // pd call suber
    c_addsub_0 pd_sub (
        .A(before_LF_plus),      // input wire [15 : 0] A
        .B(before_LF_minus),      // input wire [15 : 0] B
        .CLK(ce_clk),  // input wire CLK
        .S(pd)      // output wire [16 : 0] S
    );

    assign i_sync = i_after_nco_s;
    assign q_sync = q_after_nco_s;
    wire [22:0] loop_filter;
    wire [27:0] loop_pre_phase;
    assign loopfilter_out = {{6'b0}, loop_pre_phase[25:0]};

    loop_filter lp
    (
       .rst_n(ce_rst),
       .clk(ce_clk),
       .pd(pd),                // 鉴相器输出
       .dout(loop_filter) // loop filter 输出 22:0
    );
    
    add_pre_phase add_pre_phase (
      .A(-{{5{loop_filter[22]}},loop_filter}),  // input wire [26 : 0] A
      .S(loop_pre_phase)  // output wire [27 : 0] S
    );
    // loop_filter loop_filter(
    //     .rst_n(ce_rst),
    //     .clk(ce_clk),
    //     .pd(pd),
    //     .frequency_df(loopfilter_out)
    // );
    // assign i_sync = i_after_nco[31:16];
    // assign q_sync = q_after_nco[31:16];
endmodule
