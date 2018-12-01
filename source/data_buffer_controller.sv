// $Id: $
// File name:   data_buffer_controller.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the controller portion of data buffer module

module data_buffer_controller(

  input wire clk,
  input wire n_rst,
  input wire [7:0] rx_packet_data,
  input wire [7:0] tx_data,
  input wire [7:0] read_data
  input wire clear,
  input wire flush,
  input wire store_tx_data,
  input wire store_rx_packet_data,
  input wire get_rx_data,
  input wire get_tx_packet_data
  output reg [1:0] op,
  output reg [7:0] write_data,
  output reg [7:0] rx_data,
  output reg [7:0] tx_packet_data,
  output reg read_count_enable,
  output reg write_count_enable,
  output reg empty_buffer
);

typedef enum logic [2:0] {IDLE,
                          STORE_RX,
                          STORE_TX,
                          GET_TX,
                          GET_RX,
                          CLEAR}
											state_type;

state_type state, stat_next;

typedef enum logic [1:0] {NOP,
                          WRITE,
                          READ
                          }
											op_type_type;

op_type operation;
assign operation = op;

always_comb
begin: STATE_NEXT_LOGIC

	// assigning arbitrary values
	sate_next = state;

  case(state)
    IDLE: begin
      if (store_rx_packet_data == 1) begin
       state_next = STORE_RX;
      end
      else if (store_tx_data == 1) begin
        state_next = STORE_TX;
      end
      else if (get_tx_packet_data == 1) begin
        state_next = GET_TX;
      end
      else if (get_rx_data == 1)begin
        state_next = GET_RX;
      end
      else if ( (clear == 1) | (flush = 1) ) begin
        state_next = CLEAR;
      end
    end

    STORE_RX: begin
      state_next = IDLE;
    end

    STORE_TX: begin
      state_next = IDLE;
    end

    GET_RX: begin
      state_next = IDLE;
    end

    GET_TX: begin
      state_next = IDLE;
    end

    CLEAR: begin
      state_next = IDLE;
    end
  endcase
end

// register to hold current state value
always_ff @ (posedge clk, negedge n_rst)
begin: STATE_REGISTER_LOGIC

	// if reset negation is applied
	if (1'b0 == n_rst ) begin

		// reset back to idle state
		state <= IDLE;


	end
	else begin

		// set state to next state
		state <= state_next;
	end
end

always_comb
begin: OUTPUT_LOGIC

	// assigning arbitrary values
	operation = NOP;
  write_data = 0;
  rx_data = 0;
  tx_packet_data = 0;
  read_count_enable = 0;
  write_count_enable = 0;
  empty_buffer = 0;

  case(state)

    STORE_RX: begin
      write_count_enable = 1;
      op = WRITE;
      write_data = rx_packet_data;
    end

    STORE_TX: begin
      write_count_enable = 1;
      op = WRITE;
      write_data = tx_data;
    end

    GET_TX: begin
      read_count_enable = 1;
      op = READ;
      tx_packet_data = read_data;
    end

    GET_RX: begin
      read_count_enable = 1;
      op = READ;
      rx_data = read_data;
    end

    CLEAR: begin
      empty_buffer = 1;
    end
  endcase
end
endmodule // data_buffer_controller