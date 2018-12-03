// $Id: $
// File name:   set_bit_stuffer.sv
// Created:     12/3/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Few lines that sets the bit stuffer


module set_bit_stuffer(
	input wire clk,
	input wire n_rst,
	input wire [2:0] bit_stuff_counter,
	output bit_stuff
);
	assign bit_stuff = bit_stuff_counter == 3'd6;
endmodule
