// $Id: $
// File name:   controller.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Controller FSM

module controller(
	input wire clk,
	input wire n_rst,
	input wire [1:0] tx_packet,
	input wire [7:0] tx_packet_data,
	input wire [2:0] bit_stuff_counter,
	input wire encode_busy,
	input wire crc_done,
	output reg tx_enable,
	output reg tx_error,
	output reg tx_transfer_active,
	output reg load_enable,
	output reg get_tx_packet_data,
	output reg [7:0] data,
	output wire eop,
	output wire bit_stuff,
	output wire idle_state,
	output reg d_signal,
	output wire bit_strobe,
	output reg eop_end
);

	typedef enum logic [2:0] {IDLE, SYNC, PID, BUFFER, CRC1, EOP1, EOP2, EOP3, ERROR} stateType;
	stateType state;
	stateType next;
	reg[1:0] tx_clock;
	reg[7:0] tx_data;
	assign bit_strobe = (tx_clock == 2'b00);
	assign eop = (!bit_stuff && (state == EOP1 || state == EOP2));
	assign idle_state = (state == IDLE);

	always_ff @ (posedge clk, negedge n_rst)
	begin
		if(n_rst == 1'b0) begin
			state <= IDLE;
			tx_clock <= 2'b00;
		end
		else begin
			state <= next;
			tx_clock <= tx_clock + 1'b1;
		end
	end
	
	
	always_comb begin
		next = state;
		tx_enable = 1'b0;
		sync_byte = 8'b00000000;
		pid_byte = 8'b00000000;
		tx_data = 8'b00000000;
		encode_busy = 1'b0;
		tx_error = 1'b0;
		eop = 1'b0;
		eop_end = 1'b0;
		tx_transfer_active = 1'b0;
		
		case(state)
			IDLE: begin
				tx_enable = 1'b0;
				if(tx_packet == 2'b11) begin
					next = IDLE;
				end
				else begin
					next = SYNC;
				end
			end
			SYNC: begin
				tx_enable = 1'b1;
				tx_data = 8'b00000001;
				if(encode_busy == 1'b0) begin
					next = PID;
				end
				else begin
					next = SYNC;
				end
			end
			PID: begin
				tx_enable = 1'b1;
				if(tx_packet == 2'b00) begin
					tx_data = 8'b00101101;
					if(encode_busy == 1'b0) begin
						next = EOP1;
					end
				end
				else if(tx_packet == 2'b01) begin
					tx_data = 8'b10100101;
					if(encode_busy == 1'b0) begin
						next = EOP1;
					end
				end
				else if(tx_packet == 2'b10) begin
					tx_data = 8'b00111100;
					if(encode_busy == 1'b0) begin
						next = BUFFER;
					end
				end
			end
			BUFFER: begin
				tx_enable = 1'b1;
				if(buffer_occupancy == 0) begin
					next = CRC1;
				end
				else begin
					tx_data = tx_packet_data;
					get_tx_packet_data = 1'b1;
					if(encode_busy == 1'b0) begin
						next = BUFFER;
					end
				end
			end
			CRC1: begin
				crc_en = 1'b1;
				tx_enable = 1'b1;
				if(crc_done == 1'b1) begin
					if(encode_busy == 1'b0) begin
						next = EOP1;
					end
				end
			end
			EOP1: begin
				tx_enable = 1'b1;
				if(encode_busy == 1'b0) begin
					next = EOP2;
				end
			end
			EOP2: begin
				tx_enable = 1'b1;
				if(encode_busy == 1'b0) begin
					next = EOP3;
				end
			EOP3: begin
				tx_enable = 1'b1;
				if(encode_busy == 1'b0) begin
					next = IDLE;
				end
			ERROR: begin
				next = IDLE;
				tx_error = 1'b1;
			end
		endcase
	end
endmodule
