`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2016 21:57:44
// Design Name: 
// Module Name: tmds_channel
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




module tmds_channel (
	input clk,
	input reset,
	input de,
	input c0,
	input c1,
	input [7:0] data,
	output reg [9:0] q_out
	);

	reg [2:0] de_ibuf;
	reg [1:0] ctrl_ibuf [2:0];
	reg [7:0] data_ibuf;
	reg [8:0] q_m;
	reg [8:0] q_m_buf;

	reg [4:0] count;

	reg [3:0] data_n0;
	reg [3:0] data_n1;
	reg [3:0] q_m_n0;
	reg [3:0] q_m_n1;

	wire [1:0] ctrl;

	assign ctrl = {c1,c0};

/*
	initial begin
		count     <= 0;
		q_m       <= 0;
		q_out     <= 0;
		data_n0   <= 0;
		data_n1   <= 0;
		q_m_n0    <= 0;
		q_m_n1    <= 0;
		data_ibuf <= 0;
		de_ibuf   <= 0;

		ctrl_ibuf[2] <= 0;
		ctrl_ibuf[1] <= 0;
		ctrl_ibuf[0] <= 0;
	end */

//	de, ctrl, data

//	de_ibuf[2], ctrl_ibuf[2], data_ibuf, data_n0, data_n1

	always @(posedge clk) begin
		if(reset) begin
			de_ibuf[2]    <= 0;
			ctrl_ibuf[2]  <= 0;
			data_ibuf     <= 0;

			data_n0 <= 0;
			data_n1 <= 0;
		end else begin
			de_ibuf[2]    <= de;
			ctrl_ibuf[2]  <= ctrl;
			data_ibuf     <= data;

			data_n0 <= ~data[0] + ~data[1] + ~data[2] + ~data[3] + ~data[4] + ~data[5] + ~data[6] + ~data[7];
			data_n1 <=  data[0] +  data[1] +  data[2] +  data[3] +  data[4] +  data[5] +  data[6] +  data[7];
		end
	end

//	de_ibuf[2], ctrl_ibuf[2], data_ibuf, data_n0, data_n1

//	de_ibuf[1], ctrl_ibuf[1], q_m_buf

	always @(posedge clk) begin
		if(reset) begin
			de_ibuf[1]    <= 0;
			ctrl_ibuf[1]  <= 0;
			q_m_buf       <= 0;

		end else begin
			de_ibuf[1]   <= de_ibuf[2];
			ctrl_ibuf[1] <= ctrl_ibuf[2];


			if((data_n1 > 4) | ((data_n1 == 4) & (data_ibuf[0] == 0))) begin
				q_m_buf[0] = data_ibuf[0];
				q_m_buf[1] = q_m_buf[0] ^~ data_ibuf[1];
				q_m_buf[2] = q_m_buf[1] ^~ data_ibuf[2];
				q_m_buf[3] = q_m_buf[2] ^~ data_ibuf[3];
				q_m_buf[4] = q_m_buf[3] ^~ data_ibuf[4];
				q_m_buf[5] = q_m_buf[4] ^~ data_ibuf[5];
				q_m_buf[6] = q_m_buf[5] ^~ data_ibuf[6];
				q_m_buf[7] = q_m_buf[6] ^~ data_ibuf[7];
				q_m_buf[8] = 0;
			end else begin
				q_m_buf[0] = data_ibuf[0];
				q_m_buf[1] = q_m_buf[0] ^ data_ibuf[1];
				q_m_buf[2] = q_m_buf[1] ^ data_ibuf[2];
				q_m_buf[3] = q_m_buf[2] ^ data_ibuf[3];
				q_m_buf[4] = q_m_buf[3] ^ data_ibuf[4];
				q_m_buf[5] = q_m_buf[4] ^ data_ibuf[5];
				q_m_buf[6] = q_m_buf[5] ^ data_ibuf[6];
				q_m_buf[7] = q_m_buf[6] ^ data_ibuf[7];
				q_m_buf[8] = 1;
			end
		end
	end

//	de_ibuf[1], ctrl_ibuf[1], q_m_buf

//	de_ibuf[0], ctrl_ibuf[0], q_m, q_m_n0, q_m_n1

	always @(posedge clk) begin
		if(reset) begin
			de_ibuf[0]   <= 0;
			ctrl_ibuf[0] <= 0;

			q_m_n0       <= 0;
			q_m_n1       <= 0;
			q_m          <= 0;
		end else begin
			de_ibuf[0]   <= de_ibuf[1];
			ctrl_ibuf[0] <= ctrl_ibuf[1];

			q_m          <= q_m_buf;

			q_m_n0 <= ~q_m_buf[0] + ~q_m_buf[1] + ~q_m_buf[2] + ~q_m_buf[3] + ~q_m_buf[4] + ~q_m_buf[5] + ~q_m_buf[6] + ~q_m_buf[7];
			q_m_n1 <=  q_m_buf[0] +  q_m_buf[1] +  q_m_buf[2] +  q_m_buf[3] +  q_m_buf[4] +  q_m_buf[5] +  q_m_buf[6] +  q_m_buf[7];

		end
	end

//	de_ibuf[0], ctrl_ibuf[0], q_m, q_m_n0, q_m_n1

//	q_out, count, count_prev

	always @(posedge clk) begin
		if(reset) begin
			q_out <= 0;
			count = 0;
		end else begin

			if(de_ibuf[0]) begin

				if((count == 0) || (q_m_n0 == q_m_n1)) begin
					q_out[9]   <= ~q_m[8];
					q_out[8]   <=  q_m[8];
					q_out[7:0] <=  q_m[8] ? q_m[7:0] : ~q_m[7:0];

					if(q_m[8] == 0) begin
						count <=#1 count - (q_m_n1 - q_m_n0);
					end else begin
						count <=#1 count + (q_m_n1 - q_m_n0);
					end

				end else if(((~count[4]) && (q_m_n1 > 4)) || ((count[4]) && (q_m_n1 < 4))) begin
					q_out[9]   <=  1;
					q_out[8]   <=  q_m[8];
					q_out[7:0] <= ~q_m[7:0];
					count      <=#1 count + (q_m[8] << 1) - (q_m_n1 - q_m_n0); 
				end else begin
					q_out[9]   <=  0;
					q_out[8]   <=  q_m[8];
					q_out[7:0] <=  q_m[7:0];
					count      <=#1 count - (~q_m[8] << 1) + (q_m_n1 - q_m_n0); 
				end
			end else begin
				count <= 0;

				case(ctrl_ibuf[0][1:0])
				2'b00: q_out <= 10'b1101010100;
				2'b01: q_out <= 10'b0010101011;
				2'b10: q_out <= 10'b0101010100;
				2'b11: q_out <= 10'b1010101011;
				endcase
			end
		end
	end

endmodule
