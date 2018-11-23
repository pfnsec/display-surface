`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2016 15:51:40
// Design Name: 
// Module Name: selectio_tmds
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module selectio_tmds(
	input clk,
	input clk_div5,
	input reset,
	input [9:0] data,
	output dout_p,
	output dout_n
    );

	wire shift1;
	wire shift2;

	wire dout;

	wire de;

	assign de = 1;


	OBUFDS #(
	.IOSTANDARD("TMDS_33")
	) diff_output (
	.O(dout_p),
	.OB(dout_n), 
	.I(dout)
	);


	OSERDESE2 #(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.SERDES_MODE("MASTER"),
	.TRISTATE_WIDTH(1),
	.DATA_WIDTH(10),
	.INIT_OQ(1),
	.INIT_TQ(1),
	.TBYTE_CTL("FALSE"),
	.TBYTE_SRC("FALSE")
	) serial_out_m (
	.OQ(dout),
	.CLK(clk),
	.CLKDIV(clk_div5),
	.RST(reset),
	.SHIFTIN1(shift1),
	.SHIFTIN2(shift2),
	.D1(data[0]),
	.D2(data[1]),
	.D3(data[2]),
	.D4(data[3]),
	.D5(data[4]),
	.D6(data[5]),
	.D7(data[6]),
	.D8(data[7]),
	.OCE(de));


	OSERDESE2 #(
	.DATA_RATE_OQ("DDR"),
	.DATA_RATE_TQ("SDR"),
	.SERDES_MODE("SLAVE"),
	.TRISTATE_WIDTH(1),
	.DATA_WIDTH(10),
	.INIT_OQ(1),
	.INIT_TQ(1),
	.TBYTE_CTL("FALSE"),
	.TBYTE_SRC("FALSE")
	) serial_out_s (
	.CLK(clk),
	.CLKDIV(clk_div5),
	.RST(reset),
	.SHIFTOUT1(shift1),
	.SHIFTOUT2(shift2),
	.D3(data[8]),
	.D4(data[9]),
	.OCE(de));


endmodule
