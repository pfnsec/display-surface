`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2016 01:24:53
// Design Name: 
// Module Name: tmds_encode
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


module tmds_encode(
	input        hdmi_clk,
	input        reset,
	input        data_en,
	input        hsync,
	input        vsync,
	input        c0,
	input        c1,
	input        c2,
	input        c3,
	input [7:0]  tmds_0,
	input [7:0]  tmds_1,
	input [7:0]  tmds_2,
	output [9:0] q_out0,
	output [9:0] q_out1,
	output [9:0] q_out2
);


	tmds_channel hdmi0 (hdmi_clk, reset, data_en, hsync, vsync, tmds_0, q_out0);
	tmds_channel hdmi1 (hdmi_clk, reset, data_en, c0,    c1,    tmds_1, q_out1);
	tmds_channel hdmi2 (hdmi_clk, reset, data_en, c2,    c3,    tmds_2, q_out2);

endmodule
