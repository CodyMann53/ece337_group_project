// $Id: $
// File name:   tb_data_buffer.sv
// Created:     12/2/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Testbench for data buffer

`timescale 1ns / 10ps

module tb_data_buffer();

// Timing related constants
localparam CLK_PERIOD = 10;
localparam BUS_DELAY  = 800ps; // Based on FF propagation delay
localparam DATA_WIDTH = 8;

// Declare Test Case Signals
  integer tb_test_num;
  string  tb_test_case;
  string  tb_stream_check_tag;
  integer tb_bit_num;
  integer tb_curr_bit_index;
  logic   tb_mismatch;
  logic   tb_check;

//Declare Test Bench Signals for Expected Results
  logic	[(DATA_WIDTH - 1):0]	       tb_expected_tx_packet_data;
  logic [(DATA_WIDTH - 1):0]	       tb_expected_rx_data;
  logic [6:0]			       tb_expected_buffer_occupancy;



//*****************************************************************************
// General System signals
//*****************************************************************************
  logic				       tb_clk;
  logic 			       tb_n_rst;

//*****************************************************************************
// Data Buffer Signals
//*****************************************************************************
//INPUTS
  logic                                tb_clear;
  logic		                       tb_flush;
  logic			               tb_store_rx_packet_data;
  logic			               tb_get_rx_data;
  logic                                tb_get_tx_packet_data;
  logic				       tb_store_tx_data;
  logic [(DATA_WIDTH - 1):0]	       tb_tx_data;
  logic [(DATA_WIDTH - 1):0]	       tb_rx_packet_data;

//OUTPUTS
  logic	[(DATA_WIDTH - 1):0]	       tb_tx_packet_data;
  logic [(DATA_WIDTH - 1):0]	       tb_rx_data;
  logic [6:0]			       tb_buffer_occupancy;
//*****************************************************************************
// Clock Generation Block
//*****************************************************************************
// Clock generation block
always begin
  // Start with clock low to avoid false rising edge events at t=0
  tb_clk = 1'b0;
  // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
  tb_clk = 1'b1;
  // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
end

//*****************************************************************************
// DUT Instance
//*****************************************************************************
data_buffer DUT(.clk(tb_clk), .n_rst(n_rst),
		.clear(tb_clear),
		.flush(tb_flush),
		.store_rx_packet_data(tb_store_rx_packet_data),
		.get_rx_data(tb_get_rx_data),
		.get_tx_packet_data(tb_get_tx_packet_data),
		.store_tx_data(tb_store_tx_data),
		.tx_data(tb_tx_data),
		.rx_packet_data(tb_rx_packet_data),
		.tx_packet_data(tb_tx_packet_data),
		.rx_data(tb_rx_data),
		.buffer_occupancy(tb_buffer_occupancy));

//*****************************************************************************
// DUT Related TB Tasks
//*****************************************************************************
// Task for standard DUT reset procedure
task reset_dut;
begin
  // Activate the reset
  tb_n_rst = 1'b0;

  // Maintain the reset for more than one cycle
  @(posedge tb_clk);
  @(posedge tb_clk);

  // Wait until safely away from rising edge of the clock before releasing
  @(negedge tb_clk);
  tb_n_rst = 1'b1;

  // Leave out of reset for a couple cycles before allowing other stimulus
  // Wait for negative clock edges, 
  // since inputs to DUT should normally be applied away from rising clock edges
  @(negedge tb_clk);
  @(negedge tb_clk);
end
endtask

// Task to cleanly and consistently check DUT output values
task check_outputs;
  input string check_tag;
begin
  tb_mismatch = 1'b0;
  tb_check    = 1'b1;
/*  logic	[(DATA_WIDTH - 1):0]	       tb_expected_tx_packet_data;
  logic [(DATA_WIDTH - 1):0]	       tb_expected_rx_data;
  logic [6:0]			       tb_expected_buffer_occupancy;
*/

  if(tb_expected_tx_packet_data == tb_tx_packet_data) begin // Check passed
    $info("Correct 'tx_packet_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'tx_packet_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_rx_data == tb_rx_data) begin // Check passed
    $info("Correct 'rx_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'rx_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_buffer_occupancy == tb_buffer_occupancy) begin // Check passed
    $info("Correct 'buffer_occupancy' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'buffer_occupancy' output %s during %s test case", check_tag, tb_test_case);
  end

  // Wait some small amount of time so check pulse timing is visible on waves
  #(0.1);
  tb_check =1'b0;
end
endtask

//*****************************************************************************
// Bus Model Usage Related TB Tasks
//*****************************************************************************
// Task to pulse the reset for the bus model
task reset_model;
begin
  tb_model_reset = 1'b1;
  #(0.1);
  tb_model_reset = 1'b0;
end
endtask



//*****************************************************************************
//*****************************************************************************
// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // Initialize Test Case Navigation Signals
  tb_test_case        = "Initialization";
  tb_test_num	      = 0;
  tb_stream_check_tag = "N/A";
  tb_bit_num	      = -1;
  tb_curr_bit_index   = -1;
  tb_mismatch         = 1'b0;
  tb_check            = 1'b0;
  // Initialize all of the directly controled DUT inputs
  tb_n_rst          = 1'b1;
  // Initialize all of the bus model control inputs


  // Wait some time before starting first test case
  #(0.1);

  // Clear the bus model
  reset_model();

  //*****************************************************************************
  // Power-on-Reset Test Case
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Power-on-Reset";
  tb_test_case_num = tb_test_case_num + 1;
  
  // Setup provided signals with 'active' values for reset check
  tb_tx_packet_data = 8'd32;
  tb_rx_data = 8'd32;
  tb_buffer_occupancy = 6'd64;

  // Reset the DUT
  reset_dut();

  // Check outputs for reset state
  tb_expected_tx_packet_data = 'd0;
  tb_expected_rx_data = 'd0;
  tb_expected_buffer_occupancy = 'd0;
  check_outputs("after DUT reset");


end
endmodule
