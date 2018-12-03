// $Id: $
// File name:   tb_ahb_slave_lite_usb.sv
// Created:     12/2/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test Bench for ahb_slave_lite_usb

`timescale 1ns / 10ps

module tb_ahb_slave_lite_usb();

// Timing related constants
localparam CLK_PERIOD = 10;
localparam BUS_DELAY  = 800ps; // Based on FF propagation delay

// Sizing related constants
localparam DATA_WIDTH             = 2;
localparam ADDR_WIDTH             = 4;
localparam DATA_WIDTH_BITS        = DATA_WIDTH * 8;
localparam DATA_MAX_BIT           = DATA_WIDTH_BITS - 1;
localparam ADDR_MAX_BIT           = ADDR_WIDTH - 1;
localparam RX_DATA_WIDTH          = 3;
localparam TX_DATA_WIDTH	    = 3;
localparam BUFFER_OCCUPANCY_WIDTH = 7;
localparam RX_TX_DATA_WIDTH       = 8;

//HTRANS Codes
localparam TRANS_IDLE = 2'd0;
localparam TRANS_BUSY = 2'd1;
localparam TRANS_NSEQ = 2'd2;
localparam TRANS_SEQ  = 2'd3;


// Define our address mapping scheme via constants
localparam ADDR_DATA_BUFFER  = 4'd0;
localparam ADDR_STATUS       = 4'd4;
localparam ADDR_ERROR        = 4'd6;
localparam ADDR_BUFFER       = 4'd8;
localparam ADDR_TX_PACKET    = 4'd12;
localparam ADDR_FLUSH_BUFFER = 4'd13; 

// AHB-Lite-Slave reset value constants
// Student TODO: Update these based on the reset values for your config registers
//localparam RESET_COEFF  = '0;
//localparam RESET_SAMPLE = '0;

//*****************************************************************************
// Declare TB Signals (Bus Model Controls)
//*****************************************************************************
// Testing setup signals
bit                          tb_enqueue_transaction;
bit                          tb_transaction_write;
bit                          tb_transaction_fake;
bit [(ADDR_WIDTH - 1):0]     tb_transaction_addr;
bit [15:0]		       tb_transaction_data [];
bit                          tb_transaction_error;
bit [1:0]                    tb_transaction_size;
// Testing control signal(s)
logic    tb_enable_transactions;
integer  tb_current_transaction_num;
logic    tb_current_transaction_error;
logic    tb_model_reset;

string   tb_test_case;
integer  tb_test_case_num;
logic [DATA_MAX_BIT:0] tb_test_data;
string                 tb_check_tag;
logic                  tb_mismatch;
logic                  tb_check;
integer		       tb_i;

//*****************************************************************************
// General System signals
//*****************************************************************************
logic tb_clk;
logic tb_n_rst;

//*****************************************************************************
// AHB-Lite-Slave side signals
//*****************************************************************************
//AHB INPUTS
logic                                  tb_hsel;
logic [1:0]                            tb_htrans;
logic [(ADDR_WIDTH - 1):0]             tb_haddr;
logic [1:0]		               tb_hsize;
logic                                  tb_hwrite;
logic [31:0]       		       tb_hwdata;

//AHB INPUTS FROM DATA BUFFER
logic [(BUFFER_OCCUPANCY_WIDTH - 1):0] tb_buffer_occupancy;
logic [(RX_TX_DATA_WIDTH - 1):0]      tb_rx_data;

//AHB INPUTS FROM RX
logic [(RX_DATA_WIDTH - 1):0]          tb_rx_packet;
logic 			               tb_rx_data_ready;
logic			               tb_rx_transfer_active;
logic			               tb_rx_error;

//AHB INPUTS FROM TX
logic				       tb_tx_transfer_active;
logic				       tb_tx_error;

//AHB OUTPUTS
logic [31:0]			       tb_hrdata;
logic                                  tb_hresp;
logic			               tb_hready;
logic			               tb_d_mode;

//AHB OUTPUTS TO DATA BUFFER
logic				       tb_get_rx_data;
logic				       tb_store_tx_data;
logic [(RX_TX_DATA_WIDTH - 1):0]       tb_tx_data;
logic				       tb_clear;

//AHB OUTPUTS TO TX
logic [(DATA_WIDTH - 1):0]	       tb_tx_packet;

//*****************************************************************************
// TX, RX, and Data Buffer side Signals
//*****************************************************************************
logic				       tb_expected_get_rx_data;
logic 				       tb_expected_store_tx_data;
logic [(DATA_WIDTH - 1):0]	       tb_expected_tx_data;
logic [1:0]			       tb_expected_tx_packet;
logic				       tb_expected_clear;
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
// Bus Model Instance
//*****************************************************************************
ahb_lite_bus_cdl
	      #(      .DATA_WIDTH(2),
		      .ADDR_WIDTH(4))
		 BFM (.clk(tb_clk),
                  // Testing setup signals
                  .enqueue_transaction(tb_enqueue_transaction),
                  .transaction_write(tb_transaction_write),
                  .transaction_fake(tb_transaction_fake),
                  .transaction_addr(tb_transaction_addr),
                  .transaction_data(tb_transaction_data),
                  .transaction_error(tb_transaction_error),
                  .transaction_size(tb_transaction_size),
                  // Testing controls
                  .model_reset(tb_model_reset),
                  .enable_transactions(tb_enable_transactions),
                  // AHB-Lite-Slave Side
                  .hsel(tb_hsel),
                  .htrans(tb_htrans),
                  .haddr(tb_haddr),
                  .hsize(tb_hsize),
                  .hwrite(tb_hwrite),
                  .hwdata(tb_hwdata),
                  .hrdata(tb_hrdata),
                  .hresp(tb_hresp),
		  .hready(tb_hready));


//*****************************************************************************
// DUT Instance
//*****************************************************************************
ahb_slave_lite_usb DUT (.clk(tb_clk), .n_rst(tb_n_rst),
                        // AHB-Lite-Slave USB Inputs
                        .hsel(tb_hsel),
                        .htrans(tb_htrans),
                        .haddr(tb_haddr),
                        .hsize(tb_hsize),
                        .hwrite(tb_hwrite),
                        .hwdata(tb_hwdata),
			// AHB-Lite-Slave USB Inputs From Data Buffer
			.buffer_occupancy(tb_buffer_occupancy),
			.rx_data(tb_rx_data),
			// AHB-Lite-Slave USB Inputs From RX
			.rx_packet(tb_rx_packet),
			.rx_data_ready(tb_rx_data_ready),
			.rx_transfer_active(tb_rx_transfer_active),
			.rx_error(tb_rx_error),
			// AHB-Lite-Slave USB Inputs From TX
			.tx_transfer_active(tb_tx_transfer_active),
			.tx_error(tb_tx_error),
			// AHB-Lite-Slave USB Outputs
                    	.hrdata(tb_hrdata),
                    	.hresp(tb_hresp),
		    	.hready(tb_hready),
		    	.d_mode(tb_d_mode),
			// AHB-Lite-Slave USB Outputs To Data Buffer
			.get_rx_data(tb_get_rx_data),
			.store_tx_data(tb_store_tx_data),
			.tx_data(tb_tx_data),
			.clear(tb_clear),
			// AHB-Lite-Slave USB Outputs To TX
			.tx_packet(tb_tx_packet)
);

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
/*logic				       tb_expected_get_rx_data;
logic 				       tb_expected_store_tx_data;
logic [(DATA_WIDTH - 1):0]	       tb_expected_tx_data;
logic [1:0]			       tb_expected_tx_packet;
logic				       tb_expected_clear;
*/
  if(tb_expected_get_rx_data == tb_get_rx_data) begin // Check passed
    $info("Correct 'get_rx_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'get_rx_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_store_tx_data == tb_store_tx_data) begin // Check passed
    $info("Correct 'store_tx_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'store_tx_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_tx_data == tb_tx_data) begin // Check passed
    $info("Correct 'tx_data' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'tx_data' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_tx_packet == tb_tx_packet) begin // Check passed
    $info("Correct 'tx_packet' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'tx_packet' output %s during %s test case", check_tag, tb_test_case);
  end

  if(tb_expected_clear == tb_clear) begin // Check passed
    $info("Correct 'clear' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'clear' output %s during %s test case", check_tag, tb_test_case);
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

// Task to enqueue a new transaction
task enqueue_transaction;
  input bit for_dut;
  input bit write_mode;
  input bit [ADDR_MAX_BIT:0] address;
  input bit [15:0] data [];
  input bit expected_error;
  input bit [1:0] size;
begin
  // Make sure enqueue flag is low (will need a 0->1 pulse later)
  tb_enqueue_transaction = 1'b0;
  #0.1ns;

  // Setup info about transaction
  tb_transaction_fake  = ~for_dut;
  tb_transaction_write = write_mode;
  tb_transaction_addr  = address;
  tb_transaction_data  = data;
  tb_transaction_error = expected_error;
  tb_transaction_size  = {1'b0,size};

  // Pulse the enqueue flag
  tb_enqueue_transaction = 1'b1;
  #0.1ns;
  tb_enqueue_transaction = 1'b0;
end
endtask

// Task to wait for multiple transactions to happen
task execute_transactions;
  input integer num_transactions;
  integer wait_var;
begin
  // Activate the bus model
  tb_enable_transactions = 1'b1;
  @(posedge tb_clk);

  // Process the transactions (all but last one overlap 1 out of 2 cycles
  for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
    @(posedge tb_clk);
  end

  // Run out the last one (currently in data phase)
  @(posedge tb_clk);

  // Turn off the bus model
  @(negedge tb_clk);
  tb_enable_transactions = 1'b0;
end
endtask


//*****************************************************************************
//*****************************************************************************
// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // Initialize Test Case Navigation Signals
  tb_test_case       = "Initilization";
  tb_test_case_num   = -1;
  tb_test_data       = '0;
  tb_check_tag       = "N/A";
  tb_check           = 1'b0;
  tb_mismatch        = 1'b0;
  // Initialize all of the directly controled DUT inputs
  tb_n_rst          = 1'b1;
  // Initialize all of the bus model control inputs
  tb_model_reset          = 1'b0;
  tb_enable_transactions  = 1'b0;
  tb_enqueue_transaction  = 1'b0;
  tb_transaction_write    = 1'b0;
  tb_transaction_fake     = 1'b0;
  tb_transaction_addr     = '0;
  tb_transaction_data     = new[1];
  tb_transaction_error    = 1'b0;
  tb_transaction_size     = 3'd0;

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
  
  // Setup FIR Filter provided signals with 'active' values for reset check
  tb_get_rx_data = 'd1;
  tb_store_tx_data = 'd1;
  tb_tx_data = 'd1;
  tb_tx_packet = 'd1;
  tb_clear = 'd1;


  // Reset the DUT
  reset_dut();

  // Check outputs for reset state
  tb_expected_get_rx_data = 'd0;
  tb_expected_store_tx_data = 'd0;
  tb_expected_tx_data = 'd0;
  tb_expected_tx_packet = 'd0;
  tb_expected_clear = 'd0;
  check_outputs("after DUT reset");

  // Set all FIR Filter inputs back to inactive values

/*//*****************************************************************************
  // Test Case: Set a new sample value   ==== write TO ADDR_SAMPLE then READ from SR
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Send Sample";
  tb_test_case_num = tb_test_case_num + 1;

 

  // Reset the DUT to isolate from prior test case
  reset_dut();

   $info(tb_test_case);

  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
  tb_test_data = 16'd1000; 
  enqueue_transaction(1'b1, 1'b1, ADDR_SAMPLE, tb_test_data, 1'b0, 1'b1);

  enqueue_transaction(1'b1, 1'b0, ADDR_STATUS_BUSY, 8'd1, 1'b0, 1'b0);
  
  // Run the transactions via the model
  execute_transactions(2);

  // Check the DUT outputs
  tb_expected_data_ready = 1'b1;
  tb_expected_sample     = tb_test_data;
  tb_expected_load_coeff = 1'b0;
  tb_expected_coeff      = RESET_COEFF;
  check_outputs("after attempting to send a sample");


  //*****************************************************************************
  // Test Case: Configure and check a Coefficient Value
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Configure Coeff F3";
  tb_test_case_num = tb_test_case_num + 1;

  // Reset the DUT to isolate from prior test case
  reset_dut();

  $info(tb_test_case);

  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
  tb_test_data = 16'h8000; // Fixed decimal value of 1.0
  // Enqueue the write
  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 4), tb_test_data, 1'b0, 1'b1);
  // Enqueue the 'check' read
  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 4), tb_test_data, 1'b0, 1'b1);
  
  // Run the transactions via the model
  execute_transactions(2);

  // Check the DUT outputs
  tb_expected_data_ready = 1'b0;
  tb_expected_sample     = RESET_SAMPLE;
  tb_expected_load_coeff = 1'b0;
  tb_expected_coeff      = RESET_COEFF;
  check_outputs("after attempting to configure F3");


  


  //*****************************************************************************
  // Test Case: Write to bad Address
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Write Error";
  tb_test_case_num = tb_test_case_num + 1;


  $info(tb_test_case);

  // Reset the DUT to isolate from prior test case
  reset_dut();

  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
  tb_test_data = 16'h8000; // Fixed decimal value of 1.0
  // Enqueue the write
  enqueue_transaction(1'b1, 1'b1, ADDR_STATUS, tb_test_data, 1'b1, 1'b1);

  //Enqueue write to F0
  enqueue_transaction(1'b1, 1'b1, ADDR_COEF_START, tb_test_data, 1'b0, 1'b1);
  // Enqueue the 'check' read
  enqueue_transaction(1'b1, 1'b0, ADDR_COEF_START, tb_test_data, 1'b0, 1'b1);
  
  // Run the transactions via the model
  execute_transactions(3);

  // Check the DUT outputs
  tb_expected_data_ready = 1'b0;
  tb_expected_sample     = RESET_SAMPLE;
  tb_expected_load_coeff = 1'b0;
  tb_expected_coeff      = RESET_COEFF;
  check_outputs("after attempting write to bad address then config F0");


  //*****************************************************************************
  // Test Case: Acitvate Load and check SR
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Acitvate Load and check SR";
  tb_test_case_num = tb_test_case_num + 1;
  $info(tb_test_case);
  

  // Reset the DUT to isolate from prior test case
  reset_dut();

  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
  tb_test_data = 16'h8000; // Fixed decimal value of 1.0

  enqueue_transaction(1'b1, 1'b1, ADDR_COEF_START, tb_test_data, 1'b0, 1'b1);
  execute_transactions(1);
  // Enqueue the write to activate load
  enqueue_transaction(1'b1, 1'b1, ADDR_COEF_SET, 16'd1, 1'b0, 1'b1);
  execute_transactions(1);

  //Enqueue read from SR
  enqueue_transaction(1'b1, 1'b0, ADDR_STATUS, 16'd1, 1'b0, 1'b1);
  execute_transactions(1);
  
  
  // Run the transactions via the model
  // execute_transactions(3);

  // Check the DUT outputs
  tb_expected_data_ready = 1'b0;
  tb_expected_sample     = RESET_SAMPLE;
  tb_expected_load_coeff = 1'b1;
  tb_expected_coeff      = tb_test_data;
  check_outputs("after attempting to activate load and check SR");
*/
end
endmodule
