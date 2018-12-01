// $Id: $
// File name:   counter.sv
// Created:     10/19/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is a counter to keep track of how many samples have been processed by the FIR. 

module counter (
	input wire clk, 
	input wire n_rst, 
	input wire cnt_up, 
	input wire clear, 
	output reg one_k_samples
); 

reg [9:0] count; 
reg [9:0] rollover_value;

assign rollover_value = 10'd1000; 
flex_counter #(.NUM_CNT_BITS(10) )  CNT( .clk(clk), .n_rst(n_rst),
                            .clear(clear), 
                            .count_enable(cnt_up), 
                            .rollover_val(rollover_value),
                            .rollover_flag(one_k_samples), 
							.count_out(count) ); 

endmodule // counter
