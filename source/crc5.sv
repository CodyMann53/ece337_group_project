// $Id: $
// File name:   crc5.sv
// Created:     12/3/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: CRC5 for RX


module crc5(
	input wire clk,
	input wire n_rst,
	input wire crc5_enable,
	input wire d_sig,
	output crc5_out
);
	reg[4:0] crc;
	reg[4:0] crc_next;
	wire top;

	top = crc[4];
	assign crc5_out = (crc_next == 5'b01100);
	
	always_comb begin
		if(top == d_sig) begin
			next = {crc[3:0], 1'b0};
		end
		else begin
			next = {crc[3:2], !crc[1], crc[0], 1'b1};
		end
	end
	always_ff(posedge clk, negedge n_rst) begin
		if(n_rst == 1'b0) begin
			crc <= 5'b11111;
		end
		else if(crc5_enable) begin
			crc <= crc_next;
		end
	end
endmodule
