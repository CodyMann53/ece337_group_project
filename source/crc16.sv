// $Id: $
// File name:   crc16.sv
// Created:     12/2/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: CRC 16 code

module crc16(
	input wire clk,
	input wire n_rst,
	input wire crc_enable,
	input wire crc_bit_in,
	input wire dump;
	output wire crc_done,
	output wire crc_bit_out
);

	assign crc_bit_out = crc_reg[15];
	assign crc_done = (next == 16'b10000000000001101);

	reg [15:0] crc_reg;
	reg [15:0] next_crc_reg;

	always_ff @(posedge clk, negedge n_rst) begin
		if(n_rst == 1'b0) begin
			crc_reg <= 16'hffff;
		end
		else begin
			crc_reg <= next_crc_reg;
		end
	end
	
	always_comb begin
		if(dump || out == crc_bit_out) begin
			next_crc_reg = {crc_reg[14:0], 1'b0};
		end
		else begin
			next_crc_reg = {!crc_reg[14], crc_reg[13:2], !crc_reg[1], crc_reg[0], 1'b1};
		end
	end
endmodule

	
