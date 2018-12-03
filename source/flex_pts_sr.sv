// $Id: $
// File name:   flex_pts_sr.sv
// Created:     9/19/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Flexible and Scalable Parallel-to-Serial Shift Register Design

module flex_pts_sr
#(
	NUM_BITS = 4,
	SHIFT_MSB = 1
)
(
	input wire clk,
	input wire n_rst,
	input wire shift_enable,
	input wire load_enable,
	input wire [NUM_BITS-1:0] parallel_in,
	output reg serial_out
);
	reg [NUM_BITS-1:0] next;
	reg [NUM_BITS-1:0] parallel_out;

	always_ff @ (posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0)
		begin
			parallel_out <= '1;
		end
		else
		begin
			parallel_out <= next;
		end
	end
	always_comb begin
		if (load_enable == 1)
		begin
			next = parallel_in;
		end
		else
		begin
			if (shift_enable == 1) begin
				if (SHIFT_MSB == 1) begin
					next = {parallel_out[NUM_BITS-2:0], 1'b1};
				end
				else begin
					next = {1'b1, parallel_out[NUM_BITS-1:1]};
				end
			end
			else
			begin
				next = parallel_out;
			end
		end
	end
	if (SHIFT_MSB == 0) begin
		assign serial_out = parallel_out[0];
	end
	else begin
		assign serial_out = parallel_out[NUM_BITS-1];
	end
endmodule
