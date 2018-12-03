// $Id: $
// File name:   data_buffer.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the heiharchal file for the data buffer module

module data_buffer(

  input wire clk,
  input wire n_rst,
  input wire clear,
  input wire flush,
  input wire store_rx_packet_data,
  input wire get_rx_data,
  input wire get_tx_packet_data,
  input wire store_tx_data,
  input wire [7:0] tx_data,
  input wire [7:0] rx_packet_data,
  output reg [7:0] tx_packet_data,
  output reg [7:0] rx_data,
  output wire [6:0] buffer_occupancy
);

// internal signal declarations
reg [5:0] rollover_val, write_rollover_flag, read_rollover_flag, write_pointer, read_pointer;
reg empty_buffer, write_count_enable, read_count_enable;
reg [1:0] op;
reg[7:0] write_data, read_data;

assign rollover_value = 6'd63;

assign buffer_occupancy = {1'b0, write_pointer - read_pointer};

flex_counter #(.NUM_CNT_BITS(6) )  WRITE_POINTER_CNT( .clk(clk), .n_rst(n_rst),
                            .clear(empty_buffer),
                            .count_enable(write_count_enable),
                            .rollover_val(rollover_value),
                            .rollover_flag(write_rollover_flag),
							              .count_out(write_pointer) );

flex_counter #(.NUM_CNT_BITS(6) )  READ_POINTER_CNT( .clk(clk), .n_rst(n_rst),
                              .clear(empty_buffer),
                              .count_enable(read_count_enable),
                              .rollover_val(rollover_value),
                              .rollover_flag(read_rollover_flag),
              							  .count_out(read_pointer) );

buffer_register_file REGISTER_FILE(.clk(clk),
                     .n_rst(n_rst),
                     .op(op),
                     .write_data(write_data),
                     .read_pointer(read_pointer),
                     .write_pointer(write_pointer),
                     .read_data(read_data));

data_buffer_controller CONTROLLER(.clk(clk),
                                  .n_rst(n_rst),
                                  .rx_packet_data(rx_packet_data),
                                  .tx_data(tx_data),
                                  .read_data(read_data),
                                  .clear(clear),
                                  .flush(flush),
                                  .store_tx_data(store_tx_data),
                                  .store_rx_packet_data(store_rx_packet_data),
                                  .get_rx_data(get_rx_data),
                                  .get_tx_packet_data(get_tx_packet_data),
                                  .op(op),
                                  .write_data(write_data),
                                  .rx_data(rx_data),
                                  .tx_packet_data(tx_packet_data),
                                  .read_count_enable(read_count_enable),
                                  .write_count_enable(write_count_enable),
                                  .empty_buffer(empty_buffer));
endmodule // data_buffer
