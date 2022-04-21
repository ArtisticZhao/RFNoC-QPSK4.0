`timescale 1ns / 1ps

module loop_filter
#(
	parameter AVE_DATA_NUM = 64,
	parameter AVE_DATA_BIT = 6
)
(
   input rst_n,
   input clk,
   input signed [33:0] pd,                // 鉴相器输出 sfix34_30
   input               pd_valid,
   output signed [34:0] dout,     // loop filter 输出  sfix35_30
   output reg           dout_valid
);
reg [33:0] data_reg [AVE_DATA_NUM-1:0];

reg [7:0]temp_i;

always @ (posedge clk or negedge rst_n)
if(!rst_n)
	for (temp_i=0; temp_i<AVE_DATA_NUM; temp_i=temp_i+1)
		data_reg[temp_i] <= 'd0;
else
begin
	if (pd_valid)
		data_reg[0] <= pd;
	else
		data_reg[0] <= data_reg[0];
	for (temp_i=0; temp_i<AVE_DATA_NUM-1; temp_i=temp_i+1) begin
		if (pd_valid)
			data_reg[temp_i+1] <= data_reg[temp_i];
		else
			data_reg[temp_i+1] <= data_reg[temp_i+1];
	end
end
// 位宽计算： 输入17位， 64个点叠加， 相当于 17位数 乘以64， 64 = 7位数， 因此 输出结果最多  17+7 = 24 bits
reg signed [40:0] sum;   // sfix24_15

always @ (posedge clk or negedge rst_n)
if (!rst_n)
	sum <= 'd0;
else
	if (pd_valid) begin
		sum <= sum + {{7{pd[33]}}, pd} - {{7{data_reg[AVE_DATA_NUM-1][33]}}, data_reg[AVE_DATA_NUM-1]}; //将最老的数据换为最新的输入数据
		dout_valid <= 1;
	end
	else begin
		sum <= sum;
		dout_valid <= 0;
	end
assign dout = sum[40:6]; //舍弃低6位， 相当于结果 /64 ， sfix35_30

endmodule
