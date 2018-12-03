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
	input wire crc_bit_in,
	output wire crc_done,
	output wire crc_bit_out
);

	reg [16:0] crc_reg;
	reg [3:0] bit_counter;
	assign crc_bit_out = crc[~bit_counter];
	assign crc_done = (bit_counter == 16);

	always_ff @(posedge clk, negedge n_rst) begin
		if(n_rst == 1'b0) begin
			bit_counter <= 0;
		end
		else if(crc_done == 1'b0) begin
			bit_counter <= bit_counter + 4'd1;
		end
	end
	
	always_ff @(posedge clk, negedge n_rst) begin
		if(n_rst == 1'b0) begin
			crc_reg <= 17'd0;
		end
		else begin
			crc_reg[0] <= ~(crc_bit_in ^ ~crc_reg[16]);
			crc_reg[1] <= ~(crc_bit_in ^ ~crc_reg[16] ^ ~crc_reg[1]);
			crc_reg[2] <= crc_reg[1];
			crc_reg[3] <= crc_reg[2];
			crc_reg[4] <= crc_reg[3];
			crc_reg[5] <= crc_reg[4];
			crc_reg[6] <= crc_reg[5];
			crc_reg[7] <= crc_reg[6];
			crc_reg[8] <= crc_reg[7];
			crc_reg[9] <= crc_reg[8];
			crc_reg[10] <= crc_reg[9];
			crc_reg[11] <= crc_reg[10];
			crc_reg[12] <= crc_reg[11];
			crc_reg[13] <= crc_reg[12];
			crc_reg[14] <= ~(crc_bit_in ^ ~crc_reg[16] ^ ~crc_reg[13]);
			crc_reg[15] <= crc_reg[14];
			crc_reg[16] <= ~(crc_bit_in ^ ~crc_reg[16]);
		end
	end
endmodule

	