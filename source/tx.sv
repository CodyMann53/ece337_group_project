// $Id: $
// File name:   tx.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: TX overarching file


module tx(
	input wire clk,
	input wire n_rst,
	input wire [7:0] tx_packet_data,
	input wire [3:0] tx_packet,
	input wire [6:0] buffer_occupancy,
	output reg dplus_out,
	output reg dminus_out,
	output reg get_tx_packetData,
	output reg tx_transferActive,
	output reg tx_error
);
reg tx_enable;
reg load_enable;
reg byte_received;
reg ack_ready;
reg check_ack;
reg ack_done;

encode encodeBlock(.clk(clk), .n_rst(n_rst), .tx_data(tx_data), .tx_enable(tx_enable), .dplus_out(dplus_out), .dminus_out(dminus_out));
controller controllerBlock(.clk(clk), .n_rst(n_rst), .start(start), .stop(stop), .byte_received(byte_received), .ack_ready(ack_ready), .check_ack(check_ack), .ack_done(ack_done), .tx_packet(tx_packet), .tx_enable(tx_enable), .tx_error(tx_error), .tx_mode(tx_mode), .load_enable(load_enable));
timer timerBlock(.clk(clk), .n_rst(n_rst), .rising_edge(rising_edge), .falling_edge(falling_edge), .start(start), .stop(stop), .byte_received(byte_received), .ack_ready(ack_ready), .check_ack(check_ack), .ack_done(ack_done));
shift_register shiftRegisterBlock(.clk(clk), .n_rst(n_rst), .load_enable(load_enable), .tx_packet_data(tx_packet_data), .falling_edge(falling_edge), .tx_enable(tx_enable), .tx_out(tx_out));