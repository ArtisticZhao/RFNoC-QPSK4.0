//
// Module: rfnoc_block_costas_tb
//
// Description: Testbench for the costas RFNoC block.
//

`default_nettype none

function string get_path_from_file(string fullpath_filename);
    int i;
    int str_index;
    logic found_path;
    string ret;


    for (i = fullpath_filename.len()-1; i>0; i=i-1) begin
        if (fullpath_filename[i] == "/") begin
            found_path=1;
            str_index=i;
            break;
        end
    end
    if (found_path==1) begin
        ret=fullpath_filename.substr(0,str_index);
    end else begin
       // `uvm_error("pve_get_path_from_file-1", $sformatf("Not found a valid path for this file: %s",fullpath_filename));
    end
        

    return ret;
endfunction


module rfnoc_block_costas_tb;

  `include "test_exec.svh"

  import PkgTestExec::*;
  import PkgChdrUtils::*;
  import PkgRfnocBlockCtrlBfm::*;
  import PkgRfnocItemUtils::*;

  //---------------------------------------------------------------------------
  // Testbench Configuration
  //---------------------------------------------------------------------------

  localparam [ 9:0] THIS_PORTID     = 10'h123;
  localparam [31:0] NOC_ID          = 32'h1053AF8F;
  localparam int    CHDR_W          = 64;
  localparam int    ITEM_W          = 32;
  localparam int    NUM_PORTS_I     = 1;
  localparam int    NUM_PORTS_O     = 1;
  localparam int    MTU             = 13;
  localparam int    SPP             = 64;
  localparam int    PKT_SIZE_BYTES  = SPP * (ITEM_W/8);
  localparam int    STALL_PROB      = 25;      // Default BFM stall probability
  localparam real   CHDR_CLK_PER    = 5.0;     // 200 MHz
  localparam real   CTRL_CLK_PER    = 25.0;    // 40 MHz

  //---------------------------------------------------------------------------
  // Clocks and Resets
  //---------------------------------------------------------------------------

  bit rfnoc_chdr_clk;
  bit rfnoc_ctrl_clk;

  sim_clock_gen #(CHDR_CLK_PER) rfnoc_chdr_clk_gen (.clk(rfnoc_chdr_clk), .rst());
  sim_clock_gen #(CTRL_CLK_PER) rfnoc_ctrl_clk_gen (.clk(rfnoc_ctrl_clk), .rst());

  //---------------------------------------------------------------------------
  // Bus Functional Models
  //---------------------------------------------------------------------------

  // Backend Interface
  RfnocBackendIf backend (rfnoc_chdr_clk, rfnoc_ctrl_clk);

  // AXIS-Ctrl Interface
  AxiStreamIf #(32) m_ctrl (rfnoc_ctrl_clk, 1'b0);
  AxiStreamIf #(32) s_ctrl (rfnoc_ctrl_clk, 1'b0);

  // AXIS-CHDR Interfaces
  AxiStreamIf #(CHDR_W) m_chdr [NUM_PORTS_I] (rfnoc_chdr_clk, 1'b0);
  AxiStreamIf #(CHDR_W) s_chdr [NUM_PORTS_O] (rfnoc_chdr_clk, 1'b0);

  // Block Controller BFM
  RfnocBlockCtrlBfm #(CHDR_W, ITEM_W) blk_ctrl = new(backend, m_ctrl, s_ctrl);

  // CHDR word and item/sample data types
  typedef ChdrData #(CHDR_W, ITEM_W)::chdr_word_t chdr_word_t;
  typedef ChdrData #(CHDR_W, ITEM_W)::item_t      item_t;

  // Connect block controller to BFMs
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_bfm_input_connections
    initial begin
      blk_ctrl.connect_master_data_port(i, m_chdr[i], PKT_SIZE_BYTES);
      blk_ctrl.set_master_stall_prob(i, STALL_PROB);
    end
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_bfm_output_connections
    initial begin
      blk_ctrl.connect_slave_data_port(i, s_chdr[i]);
      blk_ctrl.set_slave_stall_prob(i, STALL_PROB);
    end
  end

  //---------------------------------------------------------------------------
  // Device Under Test (DUT)
  //---------------------------------------------------------------------------

  // DUT Slave (Input) Port Signals
  logic [CHDR_W*NUM_PORTS_I-1:0] s_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tready;

  // DUT Master (Output) Port Signals
  logic [CHDR_W*NUM_PORTS_O-1:0] m_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tready;

  // Map the array of BFMs to a flat vector for the DUT connections
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_dut_input_connections
    // Connect BFM master to DUT slave port
    assign s_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W] = m_chdr[i].tdata;
    assign s_rfnoc_chdr_tlast[i]                = m_chdr[i].tlast;
    assign s_rfnoc_chdr_tvalid[i]               = m_chdr[i].tvalid;
    assign m_chdr[i].tready                     = s_rfnoc_chdr_tready[i];
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_dut_output_connections
    // Connect BFM slave to DUT master port
    assign s_chdr[i].tdata        = m_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W];
    assign s_chdr[i].tlast        = m_rfnoc_chdr_tlast[i];
    assign s_chdr[i].tvalid       = m_rfnoc_chdr_tvalid[i];
    assign m_rfnoc_chdr_tready[i] = s_chdr[i].tready;
  end

  rfnoc_block_costas #(
    .THIS_PORTID         (THIS_PORTID),
    .CHDR_W              (CHDR_W),
    .MTU                 (MTU)
  ) dut (
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .rfnoc_core_config   (backend.cfg),
    .rfnoc_core_status   (backend.sts),
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    .s_rfnoc_ctrl_tdata  (m_ctrl.tdata),
    .s_rfnoc_ctrl_tlast  (m_ctrl.tlast),
    .s_rfnoc_ctrl_tvalid (m_ctrl.tvalid),
    .s_rfnoc_ctrl_tready (m_ctrl.tready),
    .m_rfnoc_ctrl_tdata  (s_ctrl.tdata),
    .m_rfnoc_ctrl_tlast  (s_ctrl.tlast),
    .m_rfnoc_ctrl_tvalid (s_ctrl.tvalid),
    .m_rfnoc_ctrl_tready (s_ctrl.tready)
  );

  //---------------------------------------------------------------------------
  // Main Test Process
  //---------------------------------------------------------------------------
  initial begin : tb_main

    int fd;
    int fd_w;
    string path;
    string filename;
    $display(`__FILE__);
    path = get_path_from_file(`__FILE__);
    $display(path);
    filename = $sformatf("%s/../../../simulation/iq_data.txt", path);
    fd = $fopen(filename, "r");
    // Read sim data file
    $display("-------------------");
    if (fd) $display("File %s open successfully: %0d",filename, fd);
    else $display("File %s open failed: %0d", filename, fd);

    // Write sim data file
    filename = $sformatf("%s/../../../simulation/iq_out.txt", path);
    fd_w = $fopen(filename, "w");
    $display("-------------------");
    if (fd_w) $display("File %s open successfully: %0d", filename, fd_w);
    else $display("File %s open failed: %0d", filename, fd_w);
    
    // Initialize the test exec object for this testbench
    test.start_tb("rfnoc_block_costas_tb");

    // Start the BFMs running
    blk_ctrl.run();

    //--------------------------------
    // Reset
    //--------------------------------

    test.start_test("Flush block then reset it", 10us);
    blk_ctrl.flush_and_reset();
    test.end_test();

    //--------------------------------
    // Verify Block Info
    //--------------------------------

    test.start_test("Verify Block Info", 2us);
    `ASSERT_ERROR(blk_ctrl.get_noc_id() == NOC_ID, "Incorrect NOC_ID Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_i() == NUM_PORTS_I, "Incorrect NUM_DATA_I Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_o() == NUM_PORTS_O, "Incorrect NUM_DATA_O Value");
    `ASSERT_ERROR(blk_ctrl.get_mtu() == MTU, "Incorrect MTU Value");
    test.end_test();

    //--------------------------------
    // Test Sequences
    //--------------------------------

    begin
      // Read and write the user register to make sure it updates correctly.
      logic [31:0] write_val, read_val;
      test.start_test("Verify user register", 5us);

      // Test user register has a default value
      blk_ctrl.reg_read(dut.REG_USER_ADDR, read_val);
      `ASSERT_ERROR(
        read_val == dut.REG_USER_DEFAULT, "Incorrect default value for user register");

      // Test writing and read user register works
      write_val = $random();
      blk_ctrl.reg_write(dut.REG_USER_ADDR, write_val);
      blk_ctrl.reg_read(dut.REG_USER_ADDR, read_val);
      `ASSERT_ERROR(
        read_val == write_val, "Initial value for user register is incorrect");

      test.end_test();
    end

    begin
    
      
      int sample_val;
      int          num_bytes;
      item_t send_samples[$];
      item_t recv_samples[$];
      int state; // scanf status.

      test.start_test("Test passing through samples", 100ms);

      // Generate a payload of random samples
      while(!$feof(fd)) begin
        send_samples = {};
        for (int i = 0; i < SPP; i++) begin
          state = $fscanf(fd, "%b", sample_val);
          send_samples.push_back(sample_val); // 32-bit I,Q
        end

        // Queue a packet for transfer
        blk_ctrl.send_items(0, send_samples);

        // Receive the output packet
        blk_ctrl.recv_items(0, recv_samples);

        // Check the resulting payload size
        `ASSERT_ERROR(recv_samples.size() == SPP,
          "Received payload didn't match size of payload sent");
        for (int i = 0; i < SPP; i++) begin
          item_t sample_out;
          sample_out = recv_samples[i];
          $fwrite(fd_w, "%b\n", sample_out);
        end
      end

      // // Check the resulting samples
      // for (int i = 0; i < SPP; i++) begin
      //   item_t sample_in;
      //   item_t sample_out;

      //   sample_in  = send_samples[i];
      //   sample_out = recv_samples[i];

      //   `ASSERT_ERROR(
      //     sample_out == sample_in,
      //     $sformatf("Sample %4d, received 0x%08X, expected 0x%08X",
      //               i, sample_out, sample_in));
      // end

      test.end_test();
    end

    //--------------------------------
    // Finish Up
    //--------------------------------

    $fclose(fd);
    $fclose(fd_w);
    // Display final statistics and results
    test.end_tb();
  end : tb_main

endmodule : rfnoc_block_costas_tb


`default_nettype wire

