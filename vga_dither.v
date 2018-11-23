//Converts 24-bit pixel data sequentially to VGA 565, with dither.

module vga_dither (
	input        clk,

	input  [7:0] r_i,
	input  [7:0] g_i,
	input  [7:0] b_i,
	input        hs_i,
	input        vs_i,

	output reg [4:0] r_o,
	output reg [5:0] g_o,
	output reg [4:0] b_o,
	output reg       hs_o,
	output reg       vs_o
	);

	always @(posedge clk) begin
		r_o[4:0] <= r_i[7:3];
		g_o[5:0] <= g_i[7:2];
		b_o[4:0] <= b_i[7:3];

		hs_o     <= hs_i;
		vs_o     <= vs_i;
	end

endmodule
