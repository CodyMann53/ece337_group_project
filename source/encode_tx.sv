// $Id: $
// File name:   encode.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Encoder for TX

module encode(
	input wire clk,
	input wire n_rst,
	input wire [7:0] tx_data,
	input wire tx_enable,
	input wire encode_busy,
	output wire dplus_out,
	output wire dminus_out
);
	typedef enum logic [3:0] {IDLE, BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7} stateType;
	stateType state;
	stateType next;

	reg dplus_reg;
	reg dminus_reg;
	reg next_dplus_reg;
	reg next_dminus_reg;

	always_ff @(posedge clk, negedge n_rst)
	begin
		if(n_rst == 1'b0) begin
			state <= IDLE;
			dplus_reg <= 1'b1;
			dminus_reg <= ~dminus_reg;
			
		end
		else begin
			state <= next;
			dplus_reg <= next_dplus_reg;
			dminus_reg <= next_dminus_reg;
		end
	end

	always_comb begin
		next = state;
		next_dplus_reg = 1'b1;
		next_dminus_reg = ~dplus_reg;
		encode_busy = 1'b1;
		
		case(state)
			IDLE: begin
				if(tx_enable == 1'b1) begin
					next = BIT0;
				end
			end
			BIT0: begin
				if(tx_data[0] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT1;
			end
			BIT1: begin
				if(tx_data[1] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT2;
			end
			BIT2: begin
				if(tx_data[2] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT3;
			end
			BIT3: begin
				if(tx_data[3] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT4;
			end
			BIT4: begin
				if(tx_data[4] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT5;
			end
			BIT5: begin
				if(tx_data[5] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT6;
			end
			BIT6: begin
				if(tx_data[6] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				next = BIT7;
			end
			BIT7: begin
				if(tx_data[7] == 1'b1) begin
					next_dplus_reg = dplus_reg;
					next_dminus_reg = dminus_reg;
				end
				else begin
					next_dplus_reg = ~dplus_reg;
					next_dminus_reg = ~dminus_reg;
				end
				encode_busy = 1'b0;
				next = IDLE;
			end
		endcase
	end
	assign dplus_out = dplus_reg;
	assign dminus_out = dminus_reg;
endmodule

