`timescale 1ns / 1ps

module hdmi_fb (
	input  clk,
	input  reset,
	output reg [7:0] tmds_0,
	output reg [7:0] tmds_1,
	output reg [7:0] tmds_2,
	output reg       hsync,
	output reg       vsync,
	output           c0,
	output           c1,
	output           c2,
	output           c3,
	output reg       data_en,
	output           hdmi_enable,


	output reg [9:0] render_addr,

	output           frame_sync,
	output reg       rd_en,
	input     [31:0] din
	
);

	reg sync_pol;

	reg vsync_begin;
	reg vsync_end;

	reg [9:0] hcount;
	reg [9:0] vcount;

	reg [9:0] hsync_len;
	reg [9:0] vsync_len;
	reg [9:0] htotal;
	reg [9:0] vtotal;
	reg [9:0] hfp_len;
	reg [9:0] vfp_len;
	reg [9:0] hbp_len;
	reg [9:0] vbp_len;
	reg [9:0] hres;
	reg [9:0] vres;

	reg [9:0] xpos;
	reg [9:0] ypos;

	reg [3:0] ctrl;


	assign hdmi_enable = 1;

	assign frame_sync = (vcount == vbp_len + vsync_len) ? 1 : 0;

	assign c0 = ctrl[0];
	assign c1 = ctrl[1];
	assign c2 = ctrl[2];
	assign c3 = ctrl[3];

	always @(posedge clk) begin
		if(reset) begin
			sync_pol  <= 0;
			hcount    <= 0;
			vcount    <= 0;
			htotal    <= 800;
			vtotal    <= 525;
			hsync_len <= 96;
			vsync_len <= 2;
			hfp_len   <= 48;
			vfp_len   <= 33;
			hbp_len   <= 16;
			vbp_len   <= 12;
			hres      <= 640;
			vres      <= 480;
		end else begin
			if(hcount == htotal - 1) begin       //End of line
				hcount <= 0;

				if(vcount == vtotal - 1) begin    //End of frame
					vcount <= 0;
				end else begin
					vcount <= vcount + 1;
				end

			end else begin
				hcount <= hcount + 1;
			end
		end
	end

	//Timing signal generation
	always @(posedge clk) begin
		if(reset) begin
			hsync <= ~sync_pol;
		end else begin
			if(hcount < hsync_len) begin
	           		hsync <= sync_pol;
			end else begin
				hsync <= ~sync_pol;
			end
		end
	end

	always @(posedge clk) begin
		if(reset) begin
			vsync <= ~sync_pol;
			vsync_begin <= 0;
			vsync_end <= 0;
		end else begin
			if(vcount < vsync_len) begin
				if(vsync != sync_pol) begin
				    vsync_begin <= 1;
				end else begin
				    vsync_begin <= 0;
				end
				
				vsync <= sync_pol;

			end else begin
        
				if(vsync == sync_pol) begin
				    vsync_end <= 1;
				end else begin
				    vsync_end <= 0;
				end
				
				vsync <= ~sync_pol;
			end
		end
	end

	always @(posedge clk) begin
		if(reset) begin
			xpos        <= 0;
			ypos        <= 0;
			render_addr <= 0;
			data_en     <= 0;
			rd_en       <= 0;
			ctrl        <= 0;
		end else begin
			ctrl        <= 0;

			if(rd_en) begin
				tmds_0 <= din[7:0];
				tmds_1 <= din[15:8];
				tmds_2 <= din[23:16];
			end

//			//Active video section of horizontal scan
//			if((hcount >= hsync_len + hfp_len - 1) & (hcount < htotal - hbp_len - 1)) begin
//
//				//Active video section of vertical scan
//				if((vcount > vsync_len + vfp_len - 1) & (vcount < vtotal - vbp_len - 1)) begin

			//Active video section of horizontal scan
			if((hcount >= hsync_len + hfp_len - 1) & (hcount < htotal - hbp_len - 1)) begin

				//Active video section of vertical scan
				if((vcount >= vsync_len + vfp_len - 1) & (vcount < vtotal - vbp_len - 1)) begin

					data_en <= 1;
					rd_en   <= 1;

					if(xpos < (hres - 1)) begin
						xpos        <= xpos + 1;
						render_addr <= render_addr + 1;
					end else begin
						xpos <= 0;

						if(ypos < (vres - 1)) begin
							ypos        <= ypos + 1;
							render_addr <= render_addr + 1;
						end else begin
							ypos        <= 0;
							render_addr <= 0;
							rd_en       <= 0;
						end
					end


				end else begin
					render_addr <= 0;
					data_en     <= 0; 
					rd_en       <= 0;
					ypos        <= 0;

				end

			end else begin
				xpos    <= 0;
				data_en <= 0;
				rd_en   <= 0;

				tmds_0 <= 0;
				tmds_1 <= 0;
				tmds_2 <= 0;
			end
		end
	end

endmodule
