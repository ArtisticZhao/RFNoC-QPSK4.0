module Repeater#(
  parameter N = 4   // 重复次数
)(
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
reg [$clog2(N)-1:0] sender_cnt;  // 发送计数器

parameter IDLE       = 4'b0001;
parameter PRE_SLICE  = 4'b0010;
parameter SLICE      = 4'b0100;
parameter SLICE_LAST = 4'b1000;

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


// 发送计数器，计数值为N
always @(posedge clk or posedge reset) begin
  if (reset) begin
    sender_cnt <= 4'd0;
  end else begin
    if ((out_tvaild && out_tready) || (sample_reg && cstate == IDLE)) begin
      if (sender_cnt == N-1) begin
        sender_cnt <= 0;
      end
      else begin
        sender_cnt <= sender_cnt + 1'b1;
      end
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
      if (sender_cnt == N-2) begin
        nstate = SLICE_LAST;
      end else begin
        nstate = SLICE;
      end
    end

    SLICE_LAST: begin
      if (sender_cnt == N-1) begin
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
        // 重复输出
        out_tdata <= in_tdata_reg;
        out_tvaild <= 1'b1;
      end

      SLICE_LAST: begin
        in_tready <= 1'b1;
        // 重复输出
        out_tdata <= in_tdata_reg;
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
