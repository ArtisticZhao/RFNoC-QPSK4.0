module QPSK_data_converter (
  input               clk,
  input               reset,

  input [31:0]        in_tdata,
  input               in_tvaild,
  output reg          in_tready,

  output reg [31:0]   out_tdata,
  output reg          out_tvaild,
  input               out_tready

);

reg [3:0] cstate;
reg [3:0] nstate;
reg [3:0] sender_cnt;  // 发送计数器

parameter IDLE       = 4'b0001;
parameter PRE_SLICE  = 4'b0010;
parameter SLICE      = 4'b0100;
parameter SLICE_LAST = 4'b1000;

// 对数据映射到幅值, 目前是DAC full scale的80%
parameter ONE = 16'h6665;
parameter ZERO = 16'h999B;

wire sample;
assign sample = in_tvaild && in_tready;
reg sample_reg;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    sample_reg <= 1'b0;
  end
  else begin
    sample_reg <= sample;
  end
end

// 输入数据缓存，会导致输入数据一个周期的延迟
reg [31:0] in_tdata_reg;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    in_tdata_reg <= 32'b0;
  end
  else begin
    if (sample || nstate == SLICE_LAST) begin
      in_tdata_reg <= in_tdata;
    end
    else begin
      in_tdata_reg <= in_tdata_reg;
    end
  end
end

reg in_tvaild_reg;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    in_tvaild_reg <= 1'b0;
  end
  else begin
    in_tvaild_reg <= in_tvaild;
  end
end


// 发送计数器，当在SLICE模式下进行计数
always @(posedge clk or posedge reset) begin
  if (reset) begin
    sender_cnt <= 4'd0;
  end else begin
    if ((out_tvaild && out_tready) || (sample_reg)) begin
      sender_cnt <= sender_cnt + 1'b1;
    end
    else begin
      sender_cnt <= sender_cnt;
    end
  end
end

// fsm-1
always @(posedge clk or posedge reset) begin
  if(reset)   cstate <= IDLE;
  else        cstate <= nstate;
end

// fsm-2
always @(*) begin
  nstate = IDLE;
  case (cstate)
    IDLE: begin
      if (sample) begin
        nstate = PRE_SLICE;
      end else begin
        nstate = IDLE;
      end
    end

    PRE_SLICE: begin
      nstate = SLICE;
    end

    SLICE: begin
      if (sender_cnt == 4'd15) begin
        nstate = SLICE_LAST;
      end else begin
        nstate = SLICE;
      end
    end

    SLICE_LAST: begin
      if (sender_cnt == 4'd0) begin
        if (in_tvaild_reg)
          nstate = SLICE;
        else
          nstate = IDLE;
      end else begin
        nstate = SLICE_LAST;
      end
    end
    default: begin
      nstate = IDLE;
    end
  endcase
end


// fsm-3

wire [4:0] cnt_m2;
wire [4:0] cnt_m2p1;
wire [3:0] minus_cnt;
assign minus_cnt = 4'b1111 - sender_cnt;
assign cnt_m2 = {minus_cnt, 1'b0};    // 这个是cnt*2
assign cnt_m2p1 = {minus_cnt, 1'b1};  // cnt*2 +1
always @(posedge clk or posedge reset) begin
  if (reset) begin
    in_tready <= 0;
  end
  else begin
    case (nstate)
      IDLE: begin
        in_tready <= 1'b1;
        out_tdata <= 32'b0;
        out_tvaild <= 1'b0;
      end

      PRE_SLICE: begin
        in_tready <= 1'b0;
        out_tvaild <= 1'b0;
      end

      SLICE: begin
        in_tready <= 1'b0;
        // 下面处理输出的数据
        case ({in_tdata_reg[cnt_m2p1], in_tdata_reg[cnt_m2]})
          2'b00: begin
            out_tdata[31:0] <= {ONE, ONE};
          end
          2'b01: begin
            out_tdata[31:0] <= {ZERO, ONE};
          end
          2'b11: begin
            out_tdata[31:0] <= {ZERO, ZERO};
          end
          2'b10: begin
            out_tdata[31:0] <= {ONE, ZERO};
          end
          default: begin
            out_tdata[31:0] <= 32'b0;
          end
        endcase
        out_tvaild <= 1'b1;
      end

      SLICE_LAST: begin
        in_tready <= 1'b1;
        case ({in_tdata_reg[cnt_m2p1], in_tdata_reg[cnt_m2]})
          2'b00: begin
            out_tdata[31:0] <= {ONE, ONE};
          end
          2'b01: begin
            out_tdata[31:0] <= {ZERO, ONE};
          end
          2'b11: begin
            out_tdata[31:0] <= {ZERO, ZERO};
          end
          2'b10: begin
            out_tdata[31:0] <= {ONE, ZERO};
          end
          default: begin
            out_tdata[31:0] <= 32'b0;
          end
        endcase
      end

      default: begin
        in_tready <= 1'b1;
        out_tdata <= 32'b0;
        out_tvaild <= 1'b0;
      end
    endcase
  end
end

endmodule
