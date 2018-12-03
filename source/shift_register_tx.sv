// $Id: $
// File name:   shift_register.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Shift Register for TX

module shift_register(
	input wire clk,
	input wire n_rst,
	input wire load_enable,
	input wire [7:0] tx_packet_data,
	input wire tx_enable,
	output wire tx_out
);

logic shift_enable;
assign shift_enable = tx_enable;

flex_pts_sr #(.NUM_BITS(8), .SHIFT_MSB(1)) PTS(.clk(clk), .n_rst(n_rst), .shift_enable(shift_enable), .load_enable(load_enable), .parallel_in(tx_packet_data), .tx_out(tx_out));

endmodule
