// $Id: $
// File name:   edge_detect.sv
// Created:     12/2/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Detection of the falling edge for TX

module edge_detect (
	input wire clk,
	input wire n_rst,
	input wire d_plus,
	output reg falling_edge,
	output reg rising_edge
);

	reg reg1;
	reg reg2;
	reg reg3;

	always_ff @ (posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			reg1 <= 1'b1;
			reg2 <= 1'b1;
			reg3 <= 1'b1;
		end
		else begin
			reg1 <= d_plus;
			reg2 <= reg1;
			reg3 <= reg2;
		end
	end
	
	assign falling_edge = (reg3 && !reg2);
	assign rising_edge = (!reg3 && reg2);

endmodule
