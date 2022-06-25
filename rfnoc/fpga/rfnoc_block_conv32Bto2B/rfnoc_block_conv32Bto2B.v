// Module: rfnoc_block_conv32Bto2B
//
// Description:
//
//   This is a skeleton file for a RFNoC block. It passes incoming samples
//   to the output without any modification. A read/write user register is
//   instantiated, but left unused.
//
// Parameters:
//
//   THIS_PORTID : Control crossbar port to which this block is connected
//   CHDR_W      : AXIS-CHDR data bus width
//   MTU         : Maximum transmission unit (i.e., maximum packet size in
//                 CHDR words is 2**MTU).
//

`default_nettype none


module rfnoc_block_conv32Bto2B #(
  parameter [9:0] THIS_PORTID     = 10'd0,
  parameter       CHDR_W          = 64,
  parameter [5:0] MTU             = 10,
  parameter       N               = 4
)(
  // RFNoC Framework Clocks and Resets
  input  wire                   rfnoc_chdr_clk,
  input  wire                   rfnoc_ctrl_clk,
  input  wire                   ce_clk,
  // RFNoC Backend Interface
  input  wire [511:0]           rfnoc_core_config,
  output wire [511:0]           rfnoc_core_status,
  // AXIS-CHDR Input Ports (from framework)
  input  wire [(1)*CHDR_W-1:0]  s_rfnoc_chdr_tdata,
  input  wire [(1)-1:0]         s_rfnoc_chdr_tlast,
  input  wire [(1)-1:0]         s_rfnoc_chdr_tvalid,
  output wire [(1)-1:0]         s_rfnoc_chdr_tready,
  // AXIS-CHDR Output Ports (to framework)
  output wire [(1)*CHDR_W-1:0]  m_rfnoc_chdr_tdata,
  output wire [(1)-1:0]         m_rfnoc_chdr_tlast,
  output wire [(1)-1:0]         m_rfnoc_chdr_tvalid,
  input  wire [(1)-1:0]         m_rfnoc_chdr_tready,
  // AXIS-Ctrl Input Port (from framework)
  input  wire [31:0]            s_rfnoc_ctrl_tdata,
  input  wire                   s_rfnoc_ctrl_tlast,
  input  wire                   s_rfnoc_ctrl_tvalid,
  output wire                   s_rfnoc_ctrl_tready,
  // AXIS-Ctrl Output Port (to framework)
  output wire [31:0]            m_rfnoc_ctrl_tdata,
  output wire                   m_rfnoc_ctrl_tlast,
  output wire                   m_rfnoc_ctrl_tvalid,
  input  wire                   m_rfnoc_ctrl_tready
);

//---------------------------------------------------------------------------
  // Signal Declarations
  //---------------------------------------------------------------------------

  // Clocks and Resets
  wire               ctrlport_clk;
  wire               ctrlport_rst;
  wire               axis_data_clk;
  wire               axis_data_rst;
  // CtrlPort Master
  wire               m_ctrlport_req_wr;
  wire               m_ctrlport_req_rd;
  wire [19:0]        m_ctrlport_req_addr;
  wire [31:0]        m_ctrlport_req_data;
  wire        ctrlport_req_has_time;  // new signal
  wire [63:0] ctrlport_req_time;      // new signal
  reg                m_ctrlport_resp_ack;
  reg  [31:0]        m_ctrlport_resp_data;

  // axis data
  wire [32-1:0] m_axis_data_tdata;
  wire [1-1:0] m_axis_data_tlast;
  wire [1-1:0] m_axis_data_tvalid;
  wire [1-1:0] m_axis_data_tready;
  wire [64-1:0] m_axis_data_ttimestamp;
  wire [1-1:0] m_axis_data_thas_time;
  wire [16-1:0] m_axis_data_tlength;
  wire [1-1:0] m_axis_data_teob;
  wire [128-1:0] m_axis_data_tuser;

  wire [32-1:0] s_axis_data_tdata;
  wire [1-1:0] s_axis_data_tlast;
  wire [1-1:0] s_axis_data_tvalid;
  wire [1-1:0] s_axis_data_tready;
  wire [1*128-1:0] s_axis_data_tuser;
  wire [1-1:0] s_axis_data_teob;
  wire [1*64-1:0] s_axis_data_ttimestamp;
  wire [1-1:0] s_axis_data_thas_time;

  //---------------------------------------------------------------------------
  // NoC Shell
  //---------------------------------------------------------------------------

  noc_shell_conv32Bto2B #(
    .CHDR_W      (CHDR_W),
    .THIS_PORTID (THIS_PORTID),
    .MTU         (MTU)
  ) noc_shell_test_i (
    //---------------------
    // Framework Interface
    //---------------------

    // Clock Inputs
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    // Reset Outputs
    .rfnoc_chdr_rst      (),
    .rfnoc_ctrl_rst      (),
    // RFNoC Backend Interface
    .rfnoc_core_config   (rfnoc_core_config),
    .rfnoc_core_status   (rfnoc_core_status),
    // CHDR Input Ports  (from framework)
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    // CHDR Output Ports (to framework)
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    // AXIS-Ctrl Input Port (from framework)
    .s_rfnoc_ctrl_tdata  (s_rfnoc_ctrl_tdata),
    .s_rfnoc_ctrl_tlast  (s_rfnoc_ctrl_tlast),
    .s_rfnoc_ctrl_tvalid (s_rfnoc_ctrl_tvalid),
    .s_rfnoc_ctrl_tready (s_rfnoc_ctrl_tready),
    // AXIS-Ctrl Output Port (to framework)
    .m_rfnoc_ctrl_tdata  (m_rfnoc_ctrl_tdata),
    .m_rfnoc_ctrl_tlast  (m_rfnoc_ctrl_tlast),
    .m_rfnoc_ctrl_tvalid (m_rfnoc_ctrl_tvalid),
    .m_rfnoc_ctrl_tready (m_rfnoc_ctrl_tready),

    //---------------------
    // Client Interface
    //---------------------

    // CtrlPort Clock and Reset
    .ctrlport_clk         (ctrlport_clk),
    .ctrlport_rst         (ctrlport_rst),
    // CtrlPort Master
    .m_ctrlport_req_wr    (m_ctrlport_req_wr),
    .m_ctrlport_req_rd    (m_ctrlport_req_rd),
    .m_ctrlport_req_addr  (m_ctrlport_req_addr),
    .m_ctrlport_req_data  (m_ctrlport_req_data),
    .m_ctrlport_req_has_time(ctrlport_req_has_time),
    .m_ctrlport_req_time(ctrlport_req_time),
    .m_ctrlport_resp_ack  (m_ctrlport_resp_ack),
    .m_ctrlport_resp_data (m_ctrlport_resp_data),

    // AXI-Stream Payload Context Clock and Reset
    .axis_data_clk        (axis_data_clk),
    .axis_data_rst        (axis_data_rst),
    .m_in_axis_tdata(m_axis_data_tdata),
    .m_in_axis_tkeep(),
    .m_in_axis_tlast(m_axis_data_tlast),
    .m_in_axis_tvalid(m_axis_data_tvalid),
    .m_in_axis_tready(m_axis_data_tready),
    .m_in_axis_ttimestamp(m_axis_data_ttimestamp),
    .m_in_axis_thas_time(m_axis_data_thas_time),
    .m_in_axis_tlength(m_axis_data_tlength),
    .m_in_axis_teov(),
    .m_in_axis_teob(m_axis_data_teob),
    .s_out_axis_tdata(s_axis_data_tdata),
    .s_out_axis_tkeep(1'b1),
    .s_out_axis_tlast(s_axis_data_tlast),
    .s_out_axis_tvalid(s_axis_data_tvalid),
    .s_out_axis_tready(s_axis_data_tready),
    .s_out_axis_ttimestamp(s_axis_data_ttimestamp),
    .s_out_axis_thas_time(s_axis_data_thas_time),
    .s_out_axis_teov(1'b0),
    .s_out_axis_teob(s_axis_data_teob)
  );

  //---------------------------------------------------------------------------
  // User Registers
  //---------------------------------------------------------------------------
  //
  // There's only one register now, but we'll structure the register code to
  // make it easier to add more registers later.
  // Register use the ctrlport_clk clock.
  //
  //---------------------------------------------------------------------------

  // Note: Register addresses increment by 4
  localparam REG_USER_ADDR    = 0; // Address for example user register
  localparam REG_USER_DEFAULT = 0; // Default value for user register

  reg [31:0] reg_user = REG_USER_DEFAULT;

  always @(posedge ctrlport_clk) begin
    if (ctrlport_rst) begin
      reg_user = REG_USER_DEFAULT;
    end else begin
      // Default assignment
      m_ctrlport_resp_ack <= 0;

      // Read user register
      if (m_ctrlport_req_rd) begin // Read request
        case (m_ctrlport_req_addr)
          REG_USER_ADDR: begin
            m_ctrlport_resp_ack  <= 1;
            m_ctrlport_resp_data <= reg_user;
          end
        endcase
      end

      // Write user register
      if (m_ctrlport_req_wr) begin // Write requst
        case (m_ctrlport_req_addr)
          REG_USER_ADDR: begin
            m_ctrlport_resp_ack <= 1;
            reg_user            <= m_ctrlport_req_data[31:0];
          end
        endcase
      end
    end
  end

  //---------------------------------------------------------------------------
  // User Logic
  //---------------------------------------------------------------------------
  //
  // User logic uses the axis_data_clk clock. While the registers above use the
  // ctrlport_clk clock, in the block YAML configuration file both the control
  // and data interfaces are specified to use the rfnoc_chdr clock. Therefore,
  // we do not need to cross clock domains when using user registers with
  // user logic.
  //
  //---------------------------------------------------------------------------
  //

  // 创建chdr总线header信息
  // Build the expected tuser CHDR header
  cvita_hdr_encoder cvita_hdr_encoder (
    .pkt_type       (2'b0),
    .eob            (m_axis_data_teob[0]),
    .has_time       (m_axis_data_thas_time[0]),
    .seqnum         (12'b0),
    .payload_length (m_axis_data_tlength[0 +: 16]),
    .src_sid        (16'b0),
    .dst_sid        (16'b0),
    .vita_time      (m_axis_data_ttimestamp[0 +: 64]),
    .header         (m_axis_data_tuser[0+:128])
  );
  // 输出的header内容
  // Extract bit fields from outgoing tuser CHDR header
  assign s_axis_data_teob[0]           = s_axis_data_tuser[124 +:  1];
  assign s_axis_data_thas_time[0]      = s_axis_data_tuser[125 +:  1];
  assign s_axis_data_ttimestamp[0+:64] = s_axis_data_tuser[0 +: 64];

  // rate change 与 qpsk模块直接信号
  wire [31:0] sample_data;
  wire sample_tvalid;
  wire sample_tready;
  wire [31:0] sample_qpsk_data;
  wire sample_qpsk_tvalid;
  wire sample_qpsk_tready;

  wire [31:0] sample_qpsk_repeate_data;
  wire sample_qpsk_repeate_tvalid;
  wire sample_qpsk_repeate_tready;

  axi_rate_change #(
    .WIDTH(32),
    .DEFAULT_N(1),
    .DEFAULT_M(16*N),  // 32B 转 2B 数据量多16，每个再重复4次
    .SR_N_ADDR(0),
    .SR_M_ADDR(1),
    .SR_CONFIG_ADDR(2))
  axi_rate_change (
    .clk(axis_data_clk), .reset(axis_data_rst), .clear(0), .clear_user(),
    .src_sid(16'b0), .dst_sid(16'b0),
    .set_stb(1'b0), .set_addr(8'b0), .set_data(32'b0),  // 通过默认值设置MN，设置总线关闭
    .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready), .i_tuser(m_axis_data_tuser),
    .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid), .o_tready(s_axis_data_tready), .o_tuser(s_axis_data_tuser),
    .m_axis_data_tdata(sample_data), .m_axis_data_tlast(), .m_axis_data_tvalid(sample_tvalid), .m_axis_data_tready(sample_tready),
    .s_axis_data_tdata(sample_qpsk_repeate_data), .s_axis_data_tlast(1'b0), .s_axis_data_tvalid(sample_qpsk_repeate_tvalid), .s_axis_data_tready(sample_qpsk_repeate_tready),
    .warning_long_throttle(), .error_extra_outputs(), .error_drop_pkt_lockup()
    );

  // Repeater#(
  //   .N(4)
  // ) mt(
  //   .clk(axis_data_clk), .reset(axis_data_rst),
  //   .in_tdata(sample_data),
  //   .in_tvalid(sample_tvalid),
  //   .in_tready(sample_tready),
  //
  //   .out_tdata(sample_qpsk_repeate_data),
  //   .out_tvalid(sample_qpsk_repeate_tvalid),
  //   .out_tready(sample_qpsk_repeate_tready)
  // );

  QPSK_data_converter mt(
    .clk(axis_data_clk), .reset(axis_data_rst),
    .in_tdata(sample_data),
    .in_tvalid(sample_tvalid),
    .in_tready(sample_tready),

    .out_tdata(sample_qpsk_data),
    .out_tvalid(sample_qpsk_tvalid),
    .out_tready(sample_qpsk_tready)
  );
//  Downsizer #(
//    .G_RESET_ACTIVE(1),
//    .WIDTH(2),
//    .NUM_REG(16)
  
//  ) mt (
//    .clk(axis_data_clk), .rst(axis_data_rst),
  
//    .s_axis_tarray(sample_data[31:0]),
//    .s_axis_tvalid(sample_tvalid),
//    .s_axis_tready(sample_tready),
    
//    .m_axis_tdata(sample_qpsk_data[1:0]),
//    .m_axis_tvalid(sample_qpsk_tvalid),
//    .m_axis_tready(sample_qpsk_tready)
//  );
  

  Repeater#(
    .N(N))
  repeater(
    .clk(axis_data_clk), .reset(axis_data_rst),
    .in_tdata(sample_qpsk_data),
    .in_tvalid(sample_qpsk_tvalid),
    .in_tready(sample_qpsk_tready),

    .out_tdata(sample_qpsk_repeate_data),
    .out_tvalid(sample_qpsk_repeate_tvalid),
    .out_tready(sample_qpsk_repeate_tready)
  );



endmodule // rfnoc_block_conv32Bto2B

`default_nettype wire

