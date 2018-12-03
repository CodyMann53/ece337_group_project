// $Id: $
// File name:   tb_tx.sv
// Created:     12/2/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the test bench for the tx module .

`timescale 1ns / 10ps

module tb_tx();

// Timing related constants
localparam CLK_PERIOD = 10;
localparam TEST_DELAY = 10;
localparam BUS_DELAY  = 800ps; // Based on FF propagation delay

//****************************************************************************
// Test bench information signals
//****************************************************************************
string                 tb_test_case;
integer                tb_test_case_num;
bit   [DATA_MAX_BIT:0] tb_test_data [];
string                 tb_check_tag;
logic                  tb_mismatch;
logic                  tb_check;
integer                tb_i;

//****************************************************************************
// Expected values
//****************************************************************************
logic expected_tx_transfer_active; 
logic expected_tx_error; 
logic expected_dplus_out; 
logic expected_dminus_out; 
logic expected_get_tx_packet_data;

//*****************************************************************************
// TX input signals
//*****************************************************************************
logic [6:0] tb_buffer_occupancy;
logic [1:0] tb_tx_packet; 
logic [7:0] tb_tx_packet_data; 

//****************************************************************************
// tx output signals
//****************************************************************************
logic tb_tx_transfer_active; 
logic tb_tx_error; 
logic tb_dplus_out; 
logic tb_dminus_out; 
logic tb_get_tx_packet_data; 

//*****************************************************************************
// General System signals
//*****************************************************************************
logic tb_clk;
logic tb_n_rst;

//****************************************************************************
// Test vectors
//****************************************************************************
typedef struct{
  string test_name;
  logic [5:0] data_packet_byte_size;
  logic [63:0] data_packet [7:0];
  reg [3:0] pid;
  logic [15:0] crc;
} packet_vector;
packet_vector tb_test_packets [];

//****************************************************************************
// Enumerations
//****************************************************************************
parameter [3:0] {         OUT = 4'b0001,
                          IN = 4'b1001,
                          DATA0 = 4'b0011,
                          DATA1 = 4'b1011,
                          ACK = 4'b0010,
                          NAK = 4'b1010,
                          STALL = 4'b1110;

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
// Device Under Testing Instance
//*****************************************************************************
tx DUT(.clk(tb_clk), .n_rst(tb_n_rst),
					  .buffer_occupancy(tb_buffer_occupancy), 
					  .tx_packet(tb_tx_packet), 
					  .tx_packet_data(tb_tx_packet_data),
					  .tx_transfer_active(tb_tx_transfer_active), 
					  .tx_error(tb_tx_error), 
					  .dplus_out(tb_dplus_out), 
					  .dminus_out(tb_dminus_out), 
					  .get_tx_packet_data(tb_get_tx_packet_data)); 

//*****************************************************************************
// task definitions
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

// Task to send a packet to usb rx
task send_packet;
  input tb_test_packet;
begin
  // send the sync byte
  send_sync();

  // send the pid data
  send_pid(tb_test_packet.pid)

  // if a token or data packet
  if ((tb_test_packet.pid == OUT)   |
      (tb_test_packet.pid == IN)    |
      (tb_test_packet.pid == DATA0) |
      (tb_test_packet.pid == DATA1)) begin
      send_data(tb_test_packet.data_packet, tb_test_packet.data_packet_byte_size,
                tb_test_packet.test_name);
      send_crc(tb_test_packet.crc, tb_test_packet.pid);
  end

  // updating expected values before checking outputs
  expected_rx_error = 1'b0;
  // if the buffer is empty
  if (buffer_occupancy == 7'd0) begin
      expected_flush = 1'b0;
  end
  else begin
      expected_flush = 1'b1;
  end
  expected_rx_transfer_active = 1'b1;
  expected_store_rx_packet_data = 1'b1;

  // check outputs to make sure the transfer active signal is high
  check_outputs(tb_test_packet.test_name);

  // send EOP
  send_eop();

  // updating expected values before checking again
  expected_rx_packet = tb_test_packet.pid;
  expected_rx_data_ready = 1'b1;

  // check outputs again for verifing rest of signals
  check_outputs(tb_test_packet.test_name);

end
endtask

// task for checking all of the output signals
task check_outputs;
  input test_case_name;
begin
  // wait a little bit to allow outputs to settl
  #(1);

  // checking rx_packet data expected value
  if(tb_rx_packet_data != expected_rx_packet_data) begin
    $error("Test Case #%s has wrong rx_packet_data", tb_test_case_name);
  end

  // checking store_rx_packet_data signal
  if(tb_store_rx_packet_data != expected_store_rx_packet_data) begin
    $error("Test Case #%s has wrong store_rx_packet_data", tb_test_case_name);
  end

  // checking flush signal
  if(tb_flush != expected_flush) begin
    $error("Test Case #%s has wrong flush signal", tb_test_case_name);
  end

  // checking rx_error signal
  if(tb_rx_error != expected_rx_error) begin
    $error("Test Case #%s has wrong rx_error signal", tb_test_case_name);
  end

  // checking rx_transfer_active signal
  if(tb_rx_transfer_active != expected_rx_transfer_active) begin
    $error("Test Case #%s has wrong rx_transfer_active signal", tb_test_case_name);
  end

  // checking rx_data_ready signal
  if(tb_rx_data_ready != expected_rx_data_ready) begin
    $error("Test Case #%s has wrong rx_data_ready signal", tb_test_case_name);
  end

  // checking expected_rx_packet signal
  if(tb_rx_packet != expected_rx_packet) begin
    $error("Test Case #%s has wrong rx_packet signal", tb_test_case_name);
  end
end
endtask

// sends a sync byte
task send_sync;
begin
  // send 6 zeros
  for (int x = 0; x < 5; x++) begin
    send_bit(1'b0);
  end
  // send a 1
  send_bit(1'b1);
end
endtask

// sends the pid and then its complement back to back
task send_pid;
  input pid;
begin
  // send the 4 pid bits
  for (int x = 3; x >= 0; x++)begin
    sendbit(pid[x])
  end

  //send the 4 complemented pid bits
  for(int i = 3; i >= 0; i++)begin
    sendbit(~pid[i]);
  end
end
endtask

// send data packet up to the number of bytes that should be sent
task send_data;
  input data_packet;
  input data_packet_byte_size;
  input test_name;
begin
  // variables for indexing through bytes
  int size;
  int bit_stuff_flag = 0;
  int bit_idle_counter = 0;
  $cast(size,data_packet_byte_size);

  // loop through all of the data packet bytes and then all of the bits
  //for that individual byte
  for (int p = 0; p < size; p++) begin
    // reset the expected store_rx_packet_data signla
    expected_store_rx_packet_data = 1'b0;
    expected_rx_packet_data = 8'd0;

    //loop through alll of the bits for current packet
    for (int i = 0; i < 8; i++)begin
      // if already sent 6 idle ones
      if (bit_idle_counter == 6)begin
        // send a zero
        send_bit(1'b0);
        // don't count this as a data bit
        i--;
        // reset the idle bit counter
        bit_idle_counter = 0;
      end
      else begin // haven't sent 6 idle 1's
        // send the current bit
        send_bit(data_packet[p][i]);
        // if bit was a one
        if (data_packet[p][i] == 1'b1)begin
          // increment the idle counter
          bit_idle_counter++;
        end
        else begin // wasn't a one so can set counter back to zero
          bit_idle_counter = 0;
        end

        // check to make sure the store_rx_packet_data signal is 0
        check_outputs(test_name);
      end
    end

    //update expected values
    expected_rx_packet_data = data_packet[p];
    expected_store_rx_packet_data = 1'b1;

    // check the individual packet
    check_outputs(test_name);

  end
end
endtask

// sends the crc based on what type of packet it is
task send_crc;
  logic crc;
  logic pid;
begin
  // if a token packet
  if ((pid == OUT) | (pid == IN))begin
    //send a 5 bit crc
    for(int i = 0; i < 5; i++)begin
      send_bit(crc[i]);
    end
  end
  // if a data packet
  else if ( (pid == DATA0) | (pid == DATA1))begin
    // send a 16 bit crc
    for (int t = 0; t < 16; t++ )begin
      send_bit(crc[t]);
    end
  end
  // else do not send any crc because data field is not being used
end
endtask

// send the EOP to signify done with a packet
task send_eop;
begin
  // get away from the rising clock edge
  @(negedge tb_clk)
  // bring both d_minus and d_plus low
  tb_dplus_in = 1'b0;
  tb_dminus_in = 1'b0;
  // wait two clock cycles
  @(posedge tb_clk);
  @(posedge tb_clk);
  // get away from the rising clock edge
  @(negedge tb_clk)
  // bring d_minus and d_plus back to thier idle state
  tb_dplus_in = 1'b1;
  tb_dminus_in = 1'b0;
end
endtask

// send a bit (either one or zero)
task send_bit;
  input bit_value;
begin
  // if sending a zero
  if (bit_value == 1'b0) begin
    // get away from rising clock edge to change inputs
    @(negedge tb_clk);
    //toggle the dplus and dminus lines
    tb_dplus_in = ~tb_dplus_in;
    tb_dminus_in = ~tb_dminus_in;
    // wait a clock cycle
    @(posedge tb_clk);
  end
  else begin // do not toggle lines and wait one cycle
    @(posedge tb_clk);
  end
endtask

// sets d_plus and d_minus back to idle
task set_data_lines_to_idle;
begin
  // get away from rising clock edge
  @(negedge tb_clk);
  //set back to thier idle values
  tb_dplus_in = 1'b1;
  tb_dminus_in = 1'b0;
  // wait a clock cycle
  @(posedge tb_clk);
endtask


//*****************************************************************************
//*****************************************************************************
// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // test vector initializations
  tb_test_packets = new[3]

  // first test case/test-vector
  tb_test_case[0].test_name = "2 byte message";
  tb_test_case[0].data_packet_byte_size = 6'd2;

  tb_test_case[0].data_packet[i] = 8'd0;
  tb_test_case[1].data_packet[i] = 8'd1;

  tb_test_case[0].pid = OUT;
  tb_test_case[0].crc = 16'd26;

  // second test case/test-vector
  tb_test_case[1].test_name = "3 byte message";
  tb_test_case[1].data_packet_byte_size = 6'd3;
  for (int i=0; i<64; i++) begin
    if (i < 3) begin
      tb_test_case[1].data_packet[i] = i[7:0];
    end
  end
  tb_test_case[1].pid = OUT;
  tb_test_case[1].crc = 16'd32877;

  // third test case/test-vector
  tb_test_case[2].test_name = "4 byte message";
  tb_test_case[2].data_packet_byte_size = 6'd4;
  for (int i=0; i<64; i++) begin
    if (i < 4) begin
      tb_test_case[1].data_packet[i] = i[7:0];
    end
  end
  tb_test_case[2].pid = OUT;
  tb_test_case[2].crc = 16'd33165;

  // Initialize Test Case Navigation Signals
  tb_test_case       = "Initialization";
  tb_test_case_num   = -1;
  tb_check_tag       = "N/A";
  tb_check           = 1'b0;
  tb_mismatch        = 1'b0;
  // Initialize all of the directly controled DUT inputs
  tb_n_rst          = 1'b1;
  tb_dminus_in = 1'b0;
  tb_dplus_in = 1'b1;
  tb_buffer_occupancy = 7'd0;

  //*****************************************************************************
  // Power-on-Reset Test Case
  //*****************************************************************************
  // Update Navigation Info
  tb_test_case     = "Power-on-Reset";
  tb_test_case_num = tb_test_case_num + 1;

  // Execute each of the test packets
  for (tb_test_case_num = 0; tb_test_case_num < tb_test_packets.size(); tb_test_case_num++) begin
    // Reset the DUT
    reset_dut();
    // setting expected values
    expected_rx_packet_data = 8'd0;
    expected_store_rx_packet_data = 1'b0;
    expected_flush = 1'b0;
    expected_rx_error = 1'b0;
    expected_rx_transfer_active = 1'b0;
    expected_rx_data_ready = 1'b0;
    expected_rx_packet = 4'd0;
    // reset the d_minus and d_plus back to their idle states
    set_data_lines_to_idle();
    // Update the test name
    tb_test_case = tb_test_packets[tb_test_case_num].test_name;
    //apply the testvecto's DUT input values
    send_packet(tb_test_packets[tb_test_case_num]);
    // Wait for DUT to process the inputs
    #(TEST_DELAY - 1);
    // add some padding delay after the checks before moving on to next tb_test_case
    #(1);
  end
end
endmodule
