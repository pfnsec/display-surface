`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2016 01:48:58
// Design Name: 
// Module Name: fb_fifo
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


module fb_fifo(
	input  rclk,
	input  wclk,
	input  reset,
	input  ren,
	input  wen,
	output [31:0] rdata,
	input  [63:0] din,
	input  [9:0] raddr,
	input  [8:0] waddr,

	input frame_sync,
	input frame_sync_ack,

	output reg wfull,
	output reg rempty,

	input burst_start,
	input burst_end,

	output reg burst_ready,

	output reg block_sync,

	output [3:0] error

    );

	parameter burst_len = 16;

//	reg [9:0] raddr;
//	reg [8:0] waddr;

//fifo_select = 0 -> FIFO A reading, B writing
//fifo_select = 0 -> FIFO A reading, B writing
	reg fifo_select;

	wire fifo_a_wen;
	wire fifo_b_wen;

	wire fifo_a_ren;
	wire fifo_b_ren;

	wire [31:0] fifo_a_rdata;
	wire [31:0] fifo_b_rdata;

	wire [9:0] fifo_a_raddr;
	wire [9:0] fifo_b_raddr;

	assign rdata  = fifo_select ? fifo_b_rdata  : fifo_a_rdata;

	assign fifo_a_raddr = fifo_select ? 0 : raddr;
	assign fifo_b_raddr = fifo_select ? raddr : 0;

	assign fifo_a_ren = fifo_select ? 0 : ren;
	assign fifo_b_ren = fifo_select ? ren : 0;

//	assign fifo_a_ren = fifo_select ? 0 : ren;
//	assign fifo_b_ren = fifo_select ? ren : 0;

	assign fifo_a_wen = fifo_select ? wen : 0;
	assign fifo_b_wen = fifo_select ? 0 : wen;


	BRAM_SDP_MACRO #(
		.BRAM_SIZE("36Kb"),
		.DEVICE("7SERIES"),
		.READ_WIDTH(32),
		.WRITE_WIDTH(64),
		.DO_REG(0)
	) fifo_a (
		.DO(fifo_a_rdata),
		.DI(din),
		.RDADDR(fifo_a_raddr),
		.RDCLK(rclk),
		.RDEN(fifo_a_ren),
		.REGCE(1'b1),
		.RST(reset),
		.WRADDR(waddr),
		.WRCLK(wclk),
		.WREN(fifo_a_wen),
		.WE(8'hff)
	);

	BRAM_SDP_MACRO #(
		.BRAM_SIZE("36Kb"),
		.DEVICE("7SERIES"),
		.READ_WIDTH(32),
		.WRITE_WIDTH(64),
		.DO_REG(0)
	) fifo_b (
		.DO(fifo_b_rdata),
		.DI(din),
		.RDADDR(fifo_b_raddr),
		.RDCLK(rclk),
		.RDEN(fifo_b_ren),
		.REGCE(1'b1),
		.RST(reset),
		.WRADDR(waddr),
		.WRCLK(wclk),
		.WREN(fifo_b_wen),
		.WE(8'hff)
	);


	always @(posedge rclk) begin
		if(reset) begin
		//	raddr <= 0;
			fifo_select <= 1;
			rempty <= 1;
	//	end else if(frame_sync) begin
		//	raddr <= 0;
		//	fifo_select <= 1;
		//	fifo_select <= ~fifo_select;
		//	rempty <= 1;
		end else begin
			if(ren) begin

			//	raddr <= raddr + 1;

				if(raddr == 1023) begin
					rempty <= 1;
					fifo_select <= ~fifo_select;
				//	raddr <= 0;
				end else begin
					rempty <= 0;
				end
			end 
		end
	end
	

	always @(posedge wclk) begin
		if(reset) begin
		//	waddr  <= 0;
			wfull  <= 0;
			burst_ready <= 1;
	//	end else if(frame_sync_ack) begin
		//	waddr  <= 0;
	//		wfull  <= 0;
	//		burst_ready <= 1;
		end else begin
			if(burst_start) begin
				burst_ready <= 0;
		//		waddr[3:0]  <= 0;
			end else if(burst_end) begin
		//		waddr[8:4]  <= waddr[8:4] + 1;
				burst_ready <= 1;
		//		waddr[3:0]  <= 0;
				
		//		if(waddr[8:4] == 5'b11111) begin
		//			wfull <= 1;
		//			burst_ready <= 0;
		//		end 
		//	end else if(wen & (waddr[3:0] < 4'b1111)) begin
	//	//		if(wen) begin
		//			waddr[3:0] <= waddr[3:0] + 1;
			end else if(rempty) begin
					burst_ready <= 1;
					wfull <= 0;
		//			waddr[3:0] <= 0;
			end else begin
	//				burst_ready <= 1;
			end

//			if(wen & (waddr[3:0] < 4'b1111) & ~burst_ready) begin
		end
	end 


endmodule
