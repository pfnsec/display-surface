`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2016 01:01:26
// Design Name: 
// Module Name: display_surface
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


module display_surface (
	input              aclk,
	input              aresetn,

	output reg         fb_arvalid,
	output reg         fb_awvalid,
	output reg         fb_bready,
	output reg         fb_rready,
	output reg         fb_wlast,
	output reg         fb_wvalid,
	output reg  [5:0]  fb_arid,
	output reg  [5:0]  fb_awid,
	output reg  [5:0]  fb_wid,
	output reg  [1:0]  fb_arburst,
	output reg  [1:0]  fb_arlock,
	output reg  [2:0]  fb_arsize,
	output reg  [1:0]  fb_awburst,
	output reg  [1:0]  fb_awlock,
	output reg  [2:0]  fb_awsize,
	output reg  [2:0]  fb_arprot,
	output reg  [2:0]  fb_awprot,
	output reg  [31:0] fb_araddr,
	output reg  [31:0] fb_awaddr,
	output reg  [63:0] fb_wdata,
	output reg  [3:0]  fb_arcache,
	output reg  [3:0]  fb_arlen,
	output reg  [3:0]  fb_arqos,
	output reg  [3:0]  fb_awcache,
	output reg  [3:0]  fb_awlen,
	output reg  [3:0]  fb_awqos,
	output reg  [7:0]  fb_wstrb,
	input              fb_arready,
	input              fb_awready,
	input              fb_bvalid,
	input              fb_rlast,
	input              fb_rvalid,
	input              fb_wready,
	input       [5:0]  fb_bid,
	input       [5:0]  fb_rid,
	input       [1:0]  fb_bresp,
	input       [1:0]  fb_rresp,
	input       [63:0] fb_rdata,

	input              cfg_arvalid,
	input       [2:0]  cfg_arprot,
	input       [31:0] cfg_araddr,
	input              cfg_awvalid,
	input              cfg_bready,
	input              cfg_rready,
	input       [2:0]  cfg_awprot,
	input       [31:0] cfg_awaddr,
	input       [31:0] cfg_wdata,
	input              cfg_wvalid,
	input       [3:0]  cfg_wstrb,
	output reg         cfg_arready,
	output reg         cfg_awready,
	output reg         cfg_wready,
	output reg         cfg_bvalid,
	output reg  [1:0]  cfg_bresp,
	output reg  [1:0]  cfg_rresp,
	output reg         cfg_rvalid,
	output reg  [31:0] cfg_rdata,

	input              wfull,
	input              rempty,
	output reg  [8:0]  waddr,
	output reg  [63:0] dout,
	output reg         wr_en,

	input              frame_sync,
	output reg         frame_sync_ack,

	output reg         burst_start,
	output reg         burst_end,

	input              burst_ready
);


	parameter burst_len = 16;

	reg [31:0] cfg_awaddr_buf; 

	reg [31:0] fb_cfg; 

	`define FB_CFG_EN    0
	`define FB_CFG_IRQEN 1
	`define FB_CFG_FLIP  2
	`define FB_CFG_FBSEL 3


	reg frame_sync_pending;

	reg burst_active;

	reg  [8:0]  waddr_buf;

	reg [31:0] fb_status; 

	reg [31:0] fb_base0;

	reg [31:0] fb_base1;

	reg [31:0] fb_dim;

	wire [15:0] screen_width;
	wire [15:0] screen_height;

	assign screen_width  = fb_dim[15:0];
	assign screen_height = fb_dim[31:16];

	reg [31:0] fb_area;

	reg [63:0] dout_buf;
	reg        wr_en_buf;

	reg [20:0] rd_issue_count;

	reg [4:0] fb_state;

	`define STATE_RESET      0 
	`define STATE_IDLE       1 
	`define STATE_FLIP       2
	`define STATE_BLOCK_IDLE 3 
	`define STATE_FILL_START 4 
	`define STATE_FILL       5

	always @(posedge aclk) begin
		if(~aresetn) begin
			frame_sync_pending <= 0;
		end else begin
			if (frame_sync_ack)
				frame_sync_pending <= 0;
			else if(frame_sync)
				frame_sync_pending <= 1;
		end
	end

	always @(posedge aclk) begin
		if(~aresetn) begin
			fb_arvalid <= 0;
			fb_awvalid <= 0;
			fb_bready  <= 0;
			fb_rready  <= 0;
			fb_wlast   <= 0;
			fb_wvalid  <= 0;
			fb_arid    <= 0;
			fb_awid    <= 0;
			fb_wid     <= 0;
			fb_arburst <= 2'b01;
			fb_arlock  <= 0;
			fb_arsize  <= 3'b011;
			fb_awburst <= 0;
			fb_awlock  <= 0;
			fb_awsize  <= 0;
			fb_arprot  <= 0;
			fb_awprot  <= 0;
			fb_araddr  <= 0;
			fb_awaddr  <= 0;
			fb_wdata   <= 0;
			fb_arcache <= 4'b0011;
			fb_arlen   <= burst_len - 1;
			fb_arqos   <= 0;
			fb_awcache <= 0;
			fb_awlen   <= 0;
			fb_awqos   <= 0;
			fb_wstrb   <= 0;

			fb_state   <= `STATE_RESET;

			fb_status  <= 0; 

			dout       <= 0;
			dout_buf   <= 0;

			frame_sync_ack <= 0;

			wr_en        <= 0;
			wr_en_buf    <= 0;

			burst_start  <= 0;
			burst_end    <= 0;
			burst_active <= 0;

		end else begin


			case(fb_state)

			`STATE_RESET: begin
				fb_state <= `STATE_IDLE;
			end

			`STATE_IDLE: begin
				if(fb_cfg[`FB_CFG_EN]) begin
					fb_araddr  <= fb_base0;
					fb_arvalid <= 0;
					fb_state   <= `STATE_BLOCK_IDLE;
				end

				fb_rready  <= 0;
			end

			`STATE_FLIP: begin
				wr_en       <= 0;
				burst_start <= 0;
				burst_end   <= 0;
				waddr       <= 0;

				if(frame_sync_pending) begin
					if(fb_cfg[`FB_CFG_FLIP]) begin
						if(fb_status & `FB_CFG_FBSEL) begin
							fb_status <= fb_status & ~`FB_CFG_FBSEL;
							fb_araddr <= fb_base0;
						end else begin
							fb_status <= fb_status |  `FB_CFG_FBSEL;
							fb_araddr <= fb_base1;
						end
					end else begin
						fb_araddr <= (fb_status & `FB_CFG_FBSEL) ? fb_base1 : fb_base0; 
					end

					fb_rready      <= 0;
					fb_arvalid     <= 0;
					fb_state       <= `STATE_BLOCK_IDLE;
					rd_issue_count <= 0;
					frame_sync_ack <= 1;
				end
			end

			`STATE_BLOCK_IDLE: begin
				frame_sync_ack <= 0;
				wr_en      <= 0;

				if(rempty) begin
					fb_state   <= `STATE_FILL_START;
					fb_arvalid <= 1;
				end
			end

			`STATE_FILL_START: begin
				wr_en   <= 0;

				if(fb_arvalid & fb_arready) begin
					fb_arvalid     <= 0;
					fb_rready      <= 1;
					rd_issue_count <= rd_issue_count + 1;
					fb_state       <= `STATE_FILL;
				end
			end

			`STATE_FILL: begin
				if(fb_rvalid & fb_rready) begin
					waddr <= waddr + 1;
					wr_en <= 1;
					dout  <= fb_rdata;

					if(fb_rlast) begin
						fb_rready  <= 0;

						if(rd_issue_count == fb_dim) begin
							fb_state   <= `STATE_FLIP;
						end else begin
							fb_araddr  <= fb_araddr + (burst_len * 8);

							if(waddr == 511) begin
								fb_arvalid <= 0;
								fb_state   <= `STATE_BLOCK_IDLE;
							end else begin
								fb_arvalid <= 1;
								fb_state   <= `STATE_FILL_START;
							end
						end
					end
				end else begin
					wr_en <= 0;
					dout  <= 0;
				end
			end

			endcase
		end
	end

	reg [2:0] cfg_rstate;
	`define RD_IDLE   0
	`define RD_OUTPUT 1

	reg [2:0] cfg_wstate;
	`define WR_IDLE 0
	`define WR_WAIT 1
	`define WR_RESP 2

	always @(posedge aclk) begin
		if(~aresetn) begin
			cfg_arready <= 1;
			cfg_awready <= 1;
			cfg_bvalid  <= 0;
			cfg_rvalid  <= 0;
			cfg_wready  <= 0;
			cfg_bresp   <= 0;
			cfg_rresp   <= 0;
			cfg_rdata   <= 0;

			cfg_rstate  <= `RD_IDLE;
			cfg_wstate  <= `WR_IDLE;

			cfg_awaddr_buf <= 0;

			fb_cfg      <= 0;
			fb_dim      <= 9600;
			fb_area     <= 480 * 640 * 4;
			fb_base0    <= 0;
			fb_base1    <= 0;
		end else begin


			case(cfg_rstate)
			`RD_IDLE: begin
				cfg_arready <= 1;

				if(cfg_arvalid & cfg_arready) begin
					cfg_arready <= 0;
					cfg_rresp   <= 2'b00; //resp(OKAY)
					cfg_rstate  <= `RD_OUTPUT;
					cfg_rvalid  <= 1;

					case(cfg_araddr[7:0])
					8'h00: 
						cfg_rdata <= fb_cfg;
					8'h04:
						cfg_rdata <= fb_status;
					8'h08:
						cfg_rdata <= fb_base0;
					8'h0c:
						cfg_rdata <= fb_base1;
					8'h10:
						cfg_rdata <= fb_dim;
						
					default: begin
						cfg_rresp  <= 2'b10; //Address invalid - resp(SLVERR)
						cfg_rvalid <= 1;
					end

					endcase
				end

			end

			`RD_OUTPUT: begin
				cfg_arready <= 0;

				if(cfg_rvalid & cfg_rready) begin
					cfg_arready <= 1;
					cfg_rstate  <= `RD_IDLE;
					cfg_rvalid  <= 0;
				end
			end

			endcase

			case(cfg_wstate)
			`WR_IDLE: begin
				cfg_awready <= 1;

				if(cfg_awvalid & cfg_awready) begin
					cfg_awready <= 0;
					cfg_wready  <= 1;
					cfg_wstate  <= `WR_WAIT;
					cfg_bvalid  <= 0;

					cfg_awaddr_buf <= cfg_awaddr;

				end
			end


			`WR_WAIT: begin
				if(cfg_wready & cfg_wvalid) begin
					cfg_bresp   <= 2'b00; //resp(OKAY)
					cfg_wstate  <= `WR_RESP;
					cfg_wready  <= 0;
					cfg_bvalid  <= 1;

					case(cfg_awaddr_buf[7:0])
					8'h00: 
						fb_cfg   <= cfg_wdata;
					8'h08:
						fb_base0 <= cfg_wdata;
					8'h0c:
						fb_base1 <= cfg_wdata;
					8'h10: begin
						fb_dim   <= cfg_wdata;
				//		fb_area   =#10 (screen_width * screen_height * 4)/(burst_len * 2);
					end
						
					default:
						cfg_bresp <= 2'b10; //Address invalid - resp(SLVERR)
					
					endcase
			
				end
			end

			`WR_RESP: begin
				if(cfg_bready & cfg_bvalid) begin
					cfg_bvalid  <= 0;
					cfg_wstate  <= `WR_IDLE;
				end
			end

			endcase

		end
	end

endmodule
