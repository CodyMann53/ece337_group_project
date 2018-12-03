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
	input wire eop,
	output reg tx_enable,
	output reg tx_error,
	output reg tx_transferActive,
	output reg load_enable
);

	typedef enum logic [1:0] {IDLE, SYNC, PID, EOP} stateType;
	stateType state;
	stateType next;
	
	reg encode_busy;

	always_ff @ (posedge clk, negedge n_rst)
	begin
		if(n_rst == 1'b0) begin
			state <= IDLE;
		end
		else begin
			state <= next;
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
		tx_transferActive = 1'b0;
		
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
					next = EOP;
				end
				else if(tx_packet == 2'b1) begin
					tx_data = 8'b10100101;
					next = EOP;
				end
			end
			EOP: begin
				next = IDLE;
			end
		endcase
	end
				
				
				
/*	typedef enum logic [3:0] {IDLE, START_RECEIVED, CHECK_ADDRESS, ACK_SENT, NAK_SENT, LOAD_DATA, SEND_BYTE, CHECK_ACK, INCREMENT, ACK_RECEIVED, NAK_RECEIVED} stateType;
	stateType state;
	stateType next;

	always_ff @ (posedge clk, negedge n_rst)
	begin
		if(n_rst == 1'b0) begin
			state <= IDLE;
		end
		else begin
			state <= next;
		end
	end

	always_comb begin
		next = state;
		tx_enable = 1'b0;
		tx_error = 1'b0;
		load_enable = 1'b0;
		tx_mode = 2'b00;
		case(state)
			IDLE: begin
				if(tx_packet ) begin
					next = START_RECEIVED;
				end
				else begin
					next = IDLE;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			START_RECEIVED: begin
				if(byte_received) begin
					next = CHECK_ADDRESS;
				end
				else begin
					next = START_RECEIVED;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			CHECK_ADDRESS: begin
				if(tx_packet == 2'b00) begin
					next = ACK_SENT;
				end
				else if(tx_packet == 2'b10) begin
					next = NAK_SENT;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			NAK_SENT: begin
				if(ack_done) begin
					next = IDLE;
				end
				else begin
					next = NAK_SENT;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b10;
			end
			ACK_SENT: begin
				if(ack_done) begin
					next = LOAD_DATA;
				end
				else begin
					next = ACK_SENT;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b01;
			end
			LOAD_DATA: begin
				next = SEND_BYTE;
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b1;
				tx_mode = 2'b00;
			end
			SEND_BYTE: begin
				if(ack_ready) begin
					next = CHECK_ACK;
				end
				else begin
					next = SEND_BYTE;
				end
				tx_enable = 1'b1;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b11;
			end
			CHECK_ACK: begin
				if(d_minus && check_ack) begin
					next = NAK_RECEIVED;
				end
				else if(!d_minus && check_ack) begin
					next = INC_PNTR;
				end
				else begin
					next = CHECK_ACK;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			INCREMENT: begin
				next = ACK_RECEIVED;
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			ACK_RECEIVED: begin
				if(ack_done) begin
					next = LOAD_DATA;
				end
				else begin
					next = ACK_RECEIVED;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
			NAK_RECEIVED: begin
				if(ack_done) begin
					next = IDLE;
				end
				else begin
					next = NAK_RECEIVED;
				end
				tx_enable = 1'b0;
				tx_error = 1'b0;
				load_enable = 1'b0;
				tx_mode = 2'b00;
			end
		endcase
	end
*/
endmodule
