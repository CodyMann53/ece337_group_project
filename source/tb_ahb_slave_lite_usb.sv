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
localparam DATA_WIDTH      = 4;
localparam ADDR_WIDTH      =4 ;
localparam DATA_WIDTH_BITS = DATA_WIDTH * 8;
localparam DATA_MAX_BIT    = DATA_WIDTH_BITS - 1;
localparam ADDR_MAX_BIT    = ADDR_WIDTH - 1;

// HTRANS Codes
localparam TRANS_IDLE = 2'd0;
localparam TRANS_BUSY = 2'd1;
localparam TRANS_NSEQ = 2'd2;
localparam TRANS_SEQ  = 2'd3;

// HBURST Codes
localparam BURST_SINGLE = 3'd0;
localparam BURST_INCR   = 3'd1;
localparam BURST_WRAP4  = 3'd2;
localparam BURST_INCR4  = 3'd3;
localparam BURST_WRAP8  = 3'd4;
localparam BURST_INCR8  = 3'd5;
localparam BURST_WRAP16 = 3'd6;
localparam BURST_INCR16 = 3'd7;

//HADDR Codes
localparam ADDR_DATA_BUFFER = 4'h0; 
localparam ADDR_STATUS_REG = 4'h4; 
localparam ADDR_ERROR_REGISTER = 4'h6; 
localparam ADDR_BUFFER_OCCUP = 4'h8; 
localparam ADDR_TX_CONTROL_REG = 4'hc; 
localparam ADDR_FLUSH_BUFF_CONTROL_REG = 4'hD; 

// Define our address mapping scheme via constants
localparam ADDR_READ_MIN  = 8'd0;
localparam ADDR_READ_MAX  = 8'd127;
localparam ADDR_WRITE_MIN = 8'd64;
localparam ADDR_WRITE_MAX = 8'd255;

//*****************************************************************************
// Declare TB Signals (Bus Model Controls)
//*****************************************************************************
// Testing setup signals
bit                          tb_enqueue_transaction;
bit                          tb_transaction_write;
bit                          tb_transaction_fake;
bit [(ADDR_WIDTH - 1):0]     tb_transaction_addr;
bit [((DATA_WIDTH*8) - 1):0] tb_transaction_data [];
bit [2:0]                    tb_transaction_burst;
bit                          tb_transaction_error;
bit [2:0]                    tb_transaction_size;
// Testing control signal(s)
logic    tb_model_reset;
logic    tb_enable_transactions;
integer  tb_current_addr_transaction_num;
integer  tb_current_addr_beat_num;
logic    tb_current_addr_transaction_error;
integer  tb_current_data_transaction_num;
integer  tb_current_data_beat_num;
logic    tb_current_data_transaction_error;



//*****************************************************************************
// General test bench signals 
//*****************************************************************************
logic tb_check; 
string                 tb_test_case;
integer                tb_test_case_num;
bit   [DATA_MAX_BIT:0] tb_test_data [];
string                 tb_check_tag;
logic                  tb_mismatch;
integer                tb_i;

//*****************************************************************************
// General System signals
//*****************************************************************************
logic tb_clk;
logic tb_n_rst;

//*****************************************************************************
// AHB-Lite-Slave side signals
//*****************************************************************************
logic                          tb_hsel;
logic [2:0]                    tb_hburst;
logic [1:0]                    tb_htrans;
logic [(ADDR_WIDTH - 1):0]     tb_haddr;
logic [2:0]                    tb_hsize;
logic                          tb_hwrite;
logic [((DATA_WIDTH*8) - 1):0] tb_hwdata;
logic [((DATA_WIDTH*8) - 1):0] tb_hrdata;
logic                          tb_hresp;
logic                          tb_hready;

//****************************************************************************
// AHB-Lite-USB side signals
//****************************************************************************
logic [2:0] tb_rx_packet;
logic tb_rx_data_ready;
logic tb_rx_transfer_active; 
logic tb_rx_error; 
logic tb_d_mode;
logic [6:0] tb_buffer_occupancy;
logic [7:0] tb_rx_data;
logic tb_get_rx_data;
logic tb_store_tx_data;
logic [7:0] tb_tx_data;
logic tb_clear;
logic [1:0] tb_tx_packet;
logic tb_tx_transfer_active;
logic tb_tx_error;  

//****************************************************************************
// AHB Lite slave expected values 
//****************************************************************************
logic expected_hresp;
logic expected_d_mode;
logic expected_get_rx_data;
logic expected_store_tx_data;
logic [7:0] expected_tx_data;
logic expected_clear;
logic [1:0] expected_tx_packet;

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
ahb_lite_bus_cdl #(  .DATA_WIDTH(4), .ADDR_WIDTH(4) ) BFM (.clk(tb_clk),
                  // Testing setup signals
                  .enqueue_transaction(tb_enqueue_transaction),
                  .transaction_write(tb_transaction_write),
                  .transaction_fake(tb_transaction_fake),
                  .transaction_addr(tb_transaction_addr),
                  .transaction_size(tb_transaction_size),
                  .transaction_data(tb_transaction_data),
                  .transaction_burst(tb_transaction_burst),
                  .transaction_error(tb_transaction_error),
                  // Testing controls
                  .model_reset(tb_model_reset),
                  .enable_transactions(tb_enable_transactions),
                  .current_addr_transaction_num(tb_current_addr_transaction_num),
                  .current_addr_beat_num(tb_current_addr_beat_num),
                  .current_addr_transaction_error(tb_current_addr_transaction_error),
                  .current_data_transaction_num(tb_current_data_transaction_num),
                  .current_data_beat_num(tb_current_data_beat_num),
                  .current_data_transaction_error(tb_current_data_transaction_error),
                  // AHB-Lite-Slave Side
                  .hsel(tb_hsel),
                  .haddr(tb_haddr),
                  .hsize(tb_hsize),
                  .htrans(tb_htrans),
                  .hburst(tb_hburst),
                  .hwrite(tb_hwrite),
                  .hwdata(tb_hwdata),
                  .hrdata(tb_hrdata),
                  .hresp(tb_hresp),
                  .hready(tb_hready));

//*****************************************************************************
// Test Module Instance
//*****************************************************************************
ahb_slave_lite_usb TM ( .clk(tb_clk), .n_rst(tb_n_rst),
                        // AHB-Lite-Slave Side Bus
                        .hsel(tb_hsel),
                        .haddr(tb_haddr),
                        .hsize(tb_hsize[1:0]),
                        .htrans(tb_htrans),
                        .hwrite(tb_hwrite),
                        .hwdata(tb_hwdata),
                        .hrdata(tb_hrdata),
                        .hresp(tb_hresp),
                        .hready(tb_hready), 
                        // AHB-Lite USB side
                        .rx_packet(tb_rx_packet), 
                        .rx_data_ready(tb_rx_data_ready), 
                        .rx_transfer_active(tb_rx_transfer_active), 
                        .rx_error(tb_rx_error), 
                        .d_mode(tb_d_mode), 
                        .buffer_occupancy(tb_buffer_occupancy),
                        .rx_data(tb_rx_data), 
                        .get_rx_data(tb_get_rx_data), 
                        .store_tx_data(tb_store_tx_data), 
                        .tx_data(tb_tx_data), 
                        .clear(tb_clear), 
                        .tx_packet(tb_tx_packet), 
                        .tx_transfer_active(tb_tx_transfer_active), 
                        .tx_error(tb_tx_error));

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
  input bit [DATA_MAX_BIT:0] data [];
  input bit [2:0] burst_type;
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
  tb_transaction_burst = burst_type;

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


// Task to cleanly and consistently check DUT output values
task check_outputs;
begin
  tb_mismatch = 1'b0;
  tb_check    = 1'b1;

  // hresp 
  if ( expected_hresp != tb_hresp) begin // check failed 
    $error("Incorrect 'hresp' output during test case %s", tb_test_case); 
  end 

  // get_rx_data
  if ( expected_get_rx_data != tb_get_rx_data) begin // check failed 
    $error("Incorrect 'get_rx_data' output during test case %s", tb_test_case); 
  end 

  // d_mode
  if ( expected_d_mode != tb_d_mode) begin // check failed 
    $error("Incorrect 'd_mode' output during test case %s", tb_test_case); 
  end 

  // store_tx_data
  if ( expected_store_tx_data != tb_store_tx_data) begin // check failed 
    $error("Incorrect 'store_tx_data' output during test case %s", tb_test_case); 
  end 

  // tx_data
  if ( expected_tx_data != tb_tx_data) begin // check failed 
    $error("Incorrect 'tx_data' output during test case %s", tb_test_case); 
  end 

  // clear
  if ( expected_clear != tb_clear) begin // check failed 
    $error("Incorrect 'clear' output during test case %s", tb_test_case); 
  end 

  // tx_packet
  if ( expected_tx_packet != tb_tx_packet) begin // check failed 
    $error("Incorrect 'tx_packet' output during test case %s", tb_test_case); 
  end 

  // Wait some small amount of time so check pulse timing is visible on waves
  #(0.1);
  tb_check =1'b0;
end
endtask

task write_data_buffer;
  input bit [31:0] data [];
begin 

  // set expected values before sending write data command over ahp bus
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;

  // check expected tx data and store tx data signal before sending data to store over ahb bus 
  check_outputs(); 

    // Setup info about transaction
    //                  for dut,  write, addr,              data,         burst type       expected error,  size
    enqueue_transaction(1'b1,     1'b1,  ADDR_DATA_BUFFER,  data,        BURST_SINGLE,    1'b0,            1'b0);
    // Run the transactions via the model
    execute_transactions(1);

  // set expected values before sending write data command over ahp bus
  expected_store_tx_data = 1'b0; 
  expected_tx_data = data[0][7:0];

  //check outputs 
 check_outputs(); 
end 
endtask 

task read_status_register;
  input bit [31:0] data [];
begin 

    // Setup info about transaction
    //                  for dut,  write, addr,              data,         burst type       expected error,  size
    enqueue_transaction(1'b1,     1'b0,  ADDR_STATUS_REG,  data,        BURST_SINGLE,    1'b0,            1'b1);
    // Run the transactions via the model
    execute_transactions(1);

end 
endtask 


//*****************************************************************************
//*****************************************************************************
// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // Initialize Test Case Navigation Signals
  tb_test_case       = "Initialization";
  tb_test_case_num   = -1;
  tb_test_data       = new[1];
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
  tb_transaction_burst    = 3'd0;

  // Initialize all of the expected values  
  expected_hresp = 1'b0;   
  expected_d_mode = 1'b0; 
  expected_get_rx_data = 1'b0;  
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;  
  expected_clear = 1'b0; 
  expected_tx_packet = 2'd0;  

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
  
  // Reset the DUT
  reset_dut();

  // check for correct outputs via waveform 
  
  //*****************************************************************************
  // Test Case: apply buffer occupancy and read its value over bus
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Read Buffer Occupancy";
  tb_test_case_num = tb_test_case_num + 1;

  // Reset the DUT to isolate from prior test case
  reset_dut();

  /*Apply desired input signals on usb side*/
  // USB RX signals 
  tb_rx_packet = 3'd0;
  tb_rx_data_ready = 1'b0;
  tb_rx_transfer_active = 1'b0; 
  tb_rx_error = 1'b0;
  // Data buffer signals  
  tb_buffer_occupancy = 7'd5;
  tb_rx_data = 8'd0;
  // USB TX signals 
  tb_tx_transfer_active = 1'b0;
  tb_tx_error = 1'b0;  

  // Enqueue the needed transactions
  tb_test_data = {32'd5}; 

  // Setup info about transaction
  //                  for dut, write, addr,              data,         burst type     expect. error, size
  enqueue_transaction(1'b1,    1'b0,  ADDR_BUFFER_OCCUP, tb_test_data, BURST_SINGLE,  1'b0,   2'd1);

  // Run the transactions via the model
  execute_transactions(1);

  // check outputs 
  //check_outputs(); 

  // wait some time until the next test case
  #(10); 

  //*****************************************************************************
  // Test Case: write one byte to data buffer
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Write one byte to data buffer";
  tb_test_case_num = tb_test_case_num + 1;
  // Initialize all of the expected values  
  expected_hresp = 1'b0;   
  expected_d_mode = 1'b0; 
  expected_get_rx_data = 1'b0;  
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;  
  expected_clear = 1'b0; 
  expected_tx_packet = 2'd0;  

  // Reset the DUT to isolate from prior test case
  reset_dut();

  /*Apply desired input signals on usb side*/
  // USB RX signals 
  tb_rx_packet = 3'd0;
  tb_rx_data_ready = 1'b0;
  tb_rx_transfer_active = 1'b0; 
  tb_rx_error = 1'b0;
  // Data buffer signals  
  tb_buffer_occupancy = 7'd5;
  tb_rx_data = 8'd0;
  // USB TX signals 
  tb_tx_transfer_active = 1'b0;
  tb_tx_error = 1'b0;  

  // Enqueue the needed transactions
  tb_test_data = {32'd5};

  // write to the data buffer
  write_data_buffer(tb_test_data);

  //*****************************************************************************
  // Test Case: writing multiple bytes 
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Writing multiple bytes";
  tb_test_case_num = tb_test_case_num + 1;
  // Initialize all of the expected values  
  expected_hresp = 1'b0;   
  expected_d_mode = 1'b0; 
  expected_get_rx_data = 1'b0;  
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;  
  expected_clear = 1'b0; 
  expected_tx_packet = 2'd0;  

  // Reset the DUT to isolate from prior test case
  reset_dut();

  /*Apply desired input signals on usb side*/
  // USB RX signals 
  tb_rx_packet = 3'd0;
  tb_rx_data_ready = 1'b0;
  tb_rx_transfer_active = 1'b0; 
  tb_rx_error = 1'b0;
  // Data buffer signals  
  tb_buffer_occupancy = 7'd5;
  tb_rx_data = 8'd0;
  // USB TX signals 
  tb_tx_transfer_active = 1'b0;
  tb_tx_error = 1'b0;  

  // Enqueue the needed transactions
  tb_test_data = {32'd5};

  // write to the data buffer
  write_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd6};

  // write to the data buffer
  write_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd7};

  // write to the data buffer
  write_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd8};

  // write to the data buffer
  write_data_buffer(tb_test_data);

  //*****************************************************************************
  // Test Case: reading one byte form the data buffer 
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Reading one byte from data buffer";
  tb_test_case_num = tb_test_case_num + 1;
  // Initialize all of the expected values  
  expected_hresp = 1'b0;   
  expected_d_mode = 1'b0; 
  expected_get_rx_data = 1'b0;  
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;  
  expected_clear = 1'b0; 
  expected_tx_packet = 2'd0;  

  // Reset the DUT to isolate from prior test case
  reset_dut();

  /*Apply desired input signals on usb side*/
  // USB RX signals 
  tb_rx_packet = 3'd0;
  tb_rx_data_ready = 1'b0;
  tb_rx_transfer_active = 1'b0; 
  tb_rx_error = 1'b0;
  // Data buffer signals  
  tb_buffer_occupancy = 7'd5;
  tb_rx_data = 8'd0;
  // USB TX signals 
  tb_tx_transfer_active = 1'b0;
  tb_tx_error = 1'b0;  

  // Enqueue the needed transactions
  tb_test_data = {32'd5};

  // write to the data buffer
  read_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd6};

  // write to the data buffer
  write_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd7};

  // write to the data buffer
  write_data_buffer(tb_test_data);

    // Enqueue the needed transactions
  tb_test_data = {32'd8};

  // write to the data buffer
  write_data_buffer(tb_test_data);

  //*****************************************************************************
  // Test Case: apply buffer occupancy and read its value over bus
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Reading from status register to verify that usb rx is active";
  tb_test_case_num = tb_test_case_num + 1;
  // Initialize all of the expected values  
  expected_hresp = 1'b0;   
  expected_d_mode = 1'b0; 
  expected_get_rx_data = 1'b0;  
  expected_store_tx_data = 1'b0; 
  expected_tx_data = 8'd0;  
  expected_clear = 1'b0; 
  expected_tx_packet = 2'd0;  

  // Reset the DUT to isolate from prior test case
  reset_dut();

  /*Apply desired input signals on usb side*/
  // USB RX signals 
  tb_rx_packet = 3'd0;
  tb_rx_data_ready = 1'b0;
  tb_rx_transfer_active = 1'b0; 
  tb_rx_error = 1'b0;
  // Data buffer signals  
  tb_buffer_occupancy = 7'd5;
  tb_rx_data = 8'd0;
  // USB TX signals 
  tb_tx_transfer_active = 1'b0;
  tb_tx_error = 1'b0;  

  // setting up inputs 
  tb_rx_transfer_active = 1'b1; 

  // Enqueue the needed transactions
  tb_test_data = {32'd256};

  // write to the data buffer
  read_status_register(tb_test_data);

end

endmodule
