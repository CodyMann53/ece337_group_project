// $Id: $
// File name:   timer.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Timer for TX


module timer
(
	input wire clk,
	input wire n_rst,
	input wire rising_edge,
	input wire falling_edge,
	input wire start,
	input wire stop,
	output wire byte_received,
	output wire ack_ready,
	output wire check_ack,
	output wire ack_done
);
	typedef enum logic [2:0] { IDLE, COUNT, BYTE_RECEIVED, FALL_EDGE1, RISE_EDGE, FALL_EDGE2, CLEAR } stateType;
	stateType state;
	stateType next;

	logic count_enable;
	reg [3:0] count_out1;
	reg [3:0] count_out2;

	flex_counter TIMER1(.clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(count_enable), .rollover_val(4'd8), .count_out(count_out1), .rollover_flag(rollover_flag));
	flex_counter TIMER2(.clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(rollover_flag), .rollover_val(2'd3), .count_out(count_out2));
	

endmodule

endmodule
