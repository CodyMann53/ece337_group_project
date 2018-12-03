// $Id: $
// File name:   bit_stuffer.sv
// Created:     12/3/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Bit stuffing module for tx


module bit_stuffer (
	input wire clk,
	input wire n_rst,
	input wire d_signal,
	input wire bit_stuff,
	input wire bit_strobe,
	input wire eop,
	input wire idle_state,
	output reg [2:0] bit_stuff_counter
);

always_ff @(posedge clk, negedge n_rst) begin
	if(n_rst == 1'b0) begin
		bit_stuff_counter <= 1'b0;
	end
	else if(bit_strobe) begin
		if(idle_state == 1 || !d_signal || bit_stuff || eop) begin
			bit_stuff_counter <= 1'b0;
		end
		else begin
			bit_stuff_counter <= bit_stuff_counter + 1'b1;
		end
	end
end

endmodule
