// $Id: $
// File name:   tb_flex_counter.sv
// Created:     9/15/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for the flexible counter

`timescale 1ns / 100ps

module tb_counter();

// Define local parameters used by the test bench
localparam NUM_CNT_BITS = 10;
localparam CLK_PERIOD = 5;
localparam  FF_SETUP_TIME = 0.5;
localparam  FF_HOLD_TIME  = 0.5;
localparam  CHECK_DELAY   = (CLK_PERIOD - FF_SETUP_TIME); // Check right before the setup time starts

localparam INACTIVE_VALUE = 1'b0;
localparam RESET_OUTPUT_VALUE = INACTIVE_VALUE;

// Declare DUT portmap signals
reg tb_clk;
reg tb_n_rst;
reg tb_clear;
reg tb_cnt_up;
reg tb_one_k_samples;

// Declare test bench signals
integer tb_test_num;
string tb_test_case;
integer tb_stream_test_num;
string tb_stream_check_tag;

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
task check_output;
	input expected_value; 
	input string check_tag;

	begin
	#(1)
	if ( expected_value == tb_one_k_samples)  begin //Check passed
		$info("Correct counter flag %s during %s test case", check_tag, tb_test_case);
	end
	else begin // Check failed
		$error("Incorrect counter flag %s during %s test case", check_tag, tb_test_case);
	end
	end
endtask

//Clock generation block
always
begin
	//Start with clock low to avoid false rising edge events at t=0
	tb_clk = 1'b0;
	
	//wait half of the clokc period before toggling clock value (maintain 50% duty cycle)
	#(CLK_PERIOD / 2.0);
	tb_clk = 1'b1;
	
	// wait half of the clokc period before toggling clock value via rerunning the block (maintain 50% duty cycle)
	#(CLK_PERIOD / 2.0);
end

// DUT Port map
counter DUT(.clk(tb_clk), .n_rst(tb_n_rst), .clear(tb_clear), .tb_cnt_up(tb_cnt_up), .tb_one_k_samples(tb_one_k_samples));

initial 
begin

	// Initialize all of the test inputs
	tb_n_rst = 1'b1; // initialize to be inactive
	tb_clear = 1'b0; // set to not clear 
	tb_test_num = 0; 
	tb_cnt_up = 1'b0;
	tb_test_case = "Test bench initialization";
	tb_stream_test_num = 0;
	tb_stream_check_tag = "N/A";
	

	// Wait some time before starting first test case
	#(1)
	
	//****************************************
	// Test Case 1: Power-on Reset of the DUT
	//*****************************************
	tb_test_num = tb_test_num + 1; 
	tb_test_case = "Power on Reset";
	// Note: Do not use reset task during reset test case since we need to specifically check behavior during reset
	// wait some time before applying test case stimulus
	#(1);

	//Apply test case initial stimulus
	tb_n_rst = 1'b0; // activate reset

	//Check that the reset value is maintained during a clock cycle
	#(CLK_PERIOD * 0.5);
	check_output(RESET_OUTPUT_VALUE, "after reset applied");

	// Check that the reset value is maintained during a clock cycle
	#(CLK_PERIOD);
	check_output(RESET_OUTPUT_VALUE, "after clock cycle while in reset");

	//Release the reset away from a clock edge
	@(posedge tb_clk);
	#(2 * FF_HOLD_TIME);
	tb_n_rst = 1'b1; // Deactivate the chip reset
	#0.1;
	//Check that internal state was correctly kept after reset release
	check_output(RESET_OUTPUT_VALUE, "after reset was released");

	//****************************************
	// Test Case 2: Check that the one_k_samples flag is fired after 1000 cn_up pulses
	//*****************************************


end
endmodule

	



