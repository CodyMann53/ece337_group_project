// $Id: $
// File name:   value_registers.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the block of ahp lite slave module that handles all of the internal registering

module value_registers(

  input wire clk,
  input wire n_rst,
  input wire [3:0] val_loc,
  input wire hwrite_reg,
  input wire [31:0] hwdata,
  input wire [1:0] state,
  input wire [2:0] rx_packet,
  input wire rx_data_ready,
  input wire rx_transfer_active,
  input wire rx_error,
  input wire [6:0] buffer_occupancy,
  input wire [7:0] rx_data,
  input wire tx_transfer_active,
  input wire tx_error,
  output wire d_mode,
  output reg get_rx_data,
  output reg store_tx_data,
  output reg [7:0] tx_data,
  output reg [1:0] tx_packet,
  output reg clear,
  output reg [31:0] hrdata,
  output reg hold
);

// declaring data types for packet type
typedef enum logic [2:0] {DATA,
                          INTOKEN,
                          OUTTOKEN,
                          ACK,
                          NACK
                        }
						packet_type;

packet_type rx_pack;
assign rx_pack = rx_packet;

// declaring data types for packet type
typedef enum logic [1:0] {IDLE,
                          DATA_TRANSFER,
                          ERROR
                        }
						state_type;
state_type st;
assign st = state;

// declaring data types for packet type
typedef enum logic [1:0] {IDLE,
                          TRANSFER,
                        }
						flush_buff_type;

state_type buffStateNext, buffState;

typedef enum logic [3:0] {BUFFER4,
                          BUFFER3,
                          BUFFER2,
                          BUFFER1,
                          STATUS_LOWER,
                          STATUS_UPPER,
                          ERROR,
                          ERROR_LOWER,
                          ERROR_UPPER,
                          TX_CONTROL,
                          FLUSH_BUFFER,
                          BUFFER_OCCUP
                        }
						location_type;

location_type value_locaiton;
assign value_location = val_loc;

// signal information for the data buffer state machine
typedef enum logic [2:0] {BUFFER4,
						  BUFFER3,
						  BUFFER2,
						  BUFFER1,
						  IDLE}
						  buffer_state_machine_type;

buffer_state_machine_type data_state_next, data_state_reg;

// internal signals
reg [15:0] status_reg, status_reg_next, error_reg, error_reg_next;
reg [7:0] tx_control_reg, tx_control_reg_next, flush_buffer_reg_next, flush_buffer_reg;
reg [6:0] buffer_occup_reg;

/*D_MODE output logic */
assign d_mode = tx_transfer_active;

/* NEXT STATE LOGIC MODULE CODE */

always_comb
begin: FLUSH_BUFFER_CONTROL_STATE_MACHINE_NEXT_STATE_LOGIC

  buffStateNext = buffState; 

  case(buffState)

  	IDLE: begin 

  		if (flush_buffer_reg != 1'b0) begin 

  			buffStateNext = TRANSFER; 

  		end 
  		else begin  

  			buffStateNext = IDLE; 

  		end 
  	end 

  	TRANSFER: begin 

  		if ( flush_buffer_reg == 1'b0) begin 

  			buffStateNext = IDLE; 

  		end 
  		else begin 

  			buffStateNext = TRANSFER; 

  		end 
  	end 
  endcase 
end


always_comb
begin: FLUSH_BUFFER_CONTROL_REGISTER_NEXT_STATE_LOGIC

  flush_buffer_reg_next = flush_buffer_reg;

  if ( ( hwrite_reg == 1'b1) & (st == DATA_TRANSFER) & (value_location == FLUSH_BUFFER) ) begin
    flush_buffer_reg_next = hwdata[7:0];
  end
  else if ( clear_buffer_control == 1'b1) begin
    flush_buffer_reg_next = 8'd0;
  end
end

always_comb
begin: STATUS_REGISTER_NEXT_STATE_LOGIC

  status_reg_next = status_reg;

  if ( (rx_data_ready == 1'b1) & (rx_pack == DATA)) begin
    status_reg_next[0] = 1'b1;
  end
  else if ( (status_reg == 1'b1) & (buffer_occupancy == 1'b0) ) begin
    status_reg_next[0] = status_reg[0];
  end
  else begin
    status_reg_next[0] = 1'b0;
  end

  if ( rx_pack == INTOKEN) begin
    status_reg_next[1] = 1'b1;
  end
  else if ( (status_reg[1] == 1'b1) & (rx_data_ready == 1'b0) )begin
    status_reg_next[1] = status_reg[1];
  end
  else if ( (status_reg[1] == 1'b1 ) & (rx_data_ready == 1'b1) & (rx_pack != INTOKEN) ) begin
    status_reg_next[1] = 1'b0;
  end

  if (rx_pack == OUTTOKEN) begin
    status_reg_next[2] = 1'b1;
  end
  else if ( ( status_reg[2] == 1'b1 ) & (rx_data_ready == 1'b0) ) begin
    status_reg_next[2] = status_reg[2];
  end
  else if ( (status_reg[2] == 1'b1) & (rx_data_ready == 1'b1) & (rx_pack != OUTTOKEN) ) begin
    status_reg_next[2] = 1'b0;
  end

  if ( rx_pack == ACK) begin
    status_reg_next[3] = 1'b1;
  end
  else if ( ( status_reg[3] == 1'b1) & (rx_data_ready == 1'b0) ) begin
    status_reg_next[3] = status_reg[3];
  end
  else if ( ( status_reg[3] == 1'b1) & (rx_data_ready == 1'b1) & (rx_pack != ACK) ) begin
    status_reg_next[3] = 1'b0;
  end

  if ( rx_pack == NAK) begin
    status_reg_next[4] = 1'b1;
  end
  else if ( ( status_reg[4] == 1'b1) & (rx_data_ready == 1'b0) ) begin
    status_reg_next[4] = status_reg[4];
  end
  else if ( (status_reg[4] == 1'b1) & (rx_data_ready == 1'b1) & (rx_pack != NAK) ) begin
    status_reg_next[4] = 1'b0;
  end

  if ( rx_transfer_active == 1'b1) begin
    status_reg_next[5] = 1'b1;
  end
  else begin
    status_reg_next[5] = 1'b0;
  end

  if (tx_transfer_active == 1'b1) begin
    status_reg_next[6] = 1'b1;
  end
  else begin
    status_register[6] = 1'b0;
  end
end


always_comb
begin: TX_CONTROL_REGISTER_NEXT_STATE_LOGIC

  tx_control_reg_next = tx_control_reg;

  if ( (hwrite_reg == 1'b1) & (st == DATA_TRANSFER) & (TX_CONTROL) ) begin
    tx_control_reg_next = hwdata[7:0];
  end
  else if (clear_tx_control == 1'b1) begin
    tx_control_reg_next = 8'd0;
  end
end

always_comb
begin: ERROR_REGISTER_NEXT_STATE_LOGIC

  error_reg_next = error_reg;

  if ( rx_error == 1'b1) begin
    error_reg_next[0] = 1'b1;
  end
  else if (rx_transfer_active == 1'b0) begin
    error_reg_next[0] = error_reg[0];
  end
  else begin
    error_reg_next[0] = 1'b0;
  end

  if (tx_error == 1'b1) begin
    error_reg_next[8] = 1'b1;
  end
  else if (tx_transfer_active == 1'b0) begin
    error_reg_next[8] = error_reg[8];
  end
  else begin
    error_reg_next[8] = 1'b0;
  end
end

always_comb
begin: DATA_BUFFER_STATE_MACHINE_NEXT_STATE_LOGIC

	// assigning arbitrary values to prevent latches
	data_state_next = data_state_reg;

	case(data_state_reg) begin

		IDLE: begin
			if (state == DATA_TRANSFER) begin
				if (value_location == BUFFER4) begin
					data_state_next = BUFFER4;
				end
				else if (value_location == BUFFER3) begin
					data_state_next = BUFFER3;
				end
				else if (value_location == BUFFER2) begin
					data_state_next = BUFFER2;
				end
				else if (value_location == BUFFER1) begin
					data_state_next = BUFFEE1;
				end
				else begin
					data_state_next = IDLE;
				end
			end

		BUFFER4: begin
			data_state_next = BUFFER3;
		end

		BUFFER3: begin
			data_state_next = BUFFER2;
		end

		BUFFER2: begin
			data_state_next = BUFFER1;
		end

		BUFFER1: begin
			data_state_next = IDLE;
		end
	endcase // data_state_reg
end

/*OUTPUT LOGIC BLOCKS */
always_comb
begin: OUTPUT_LOGIC_READING

	// assigning arbitrary values to prevent latches
	hrdata = 32'd0;

	if ( ( hwrite_reg == 1'b0 ) & (state == DATA_TRANSFER) ) begin

		case(value_location)

			BUFFER4: begin
				hrdata = rx_data_reg;
			end // BUFFER4:

			BUFFER3: begin
				hrdata <= {8'd0, rx_data_reg[23:0]};
			end // BUFFER3:

			BUFFER2: begin
				hrdata = {16'd0, rx_data_reg[15:0]};
			end

			BUFFER1: begin
				hrdata = {24'd0, rx_data_reg[7:0]};
			end

			STATUS: begin
				hrdata = {16'd0, status_reg};
			end

			STATUS_LOWER: begin
				hrdata = {24'd0, sttaus_reg[7:0]};
			end

			STATUS_UPPER: begin
				hrdata = {16'd0, status_reg[15:8], 8'd0};
			end

			ERROR: begin
				hrdata = {16'd0, error_reg};
			end

			ERROR_LOWER: begin
				hrdata = {24'd0, error_reg[7:0]};
			end

			ERROR_UPPER: begin
				hrdata = {16'd0, error_reg[15:8], 8'd0};
			end

			BUFFER_OCCUP: begin
				hrdata = {24'd0, buffer_occup_reg};
			end

			TX_CONTROL: begin
				hrdata = {24'd0, tx_control_reg};
			end

			FLUSH_BUFFER: begin
				hrdata = {24'd0, flush_buff_reg};
			end
		endcase
end

always_comb
begin: DATA_BUFFER_OUTPUT_LOGIC

	// assigning arbitrary values to prevent latches
	get_rx_data = 'd0;
	store_tx_data = 'd0;
	tx_data = 'd0;
	rx_data_next = rx_data_reg;
	hold = 0;

	case(data_state_reg)

		BUFFER4: begin
			hold = 1'b1;
			if (hwrite_reg == 1'b1) begin
				store_tx_data = 1'b1;
				tx_data = hwdata[7:0];
			end
			else begin
				get_rx_data = 1'b1;
				rx_data_next = {rx_data_reg[31:8], rx_data};
			end
		end

		BUFFER3: begin
			hold = 1'b1;
			if (hwrite_reg == 1'b1) begin
				store_tx_data = 1'b1;
				tx_data = hwdata[15:7];
			end
			else begin
				get_rx_data = 1'b1;
				rx_data_next = {rx_data_reg[31:16], rx_data, rx_data_reg[7:0]};
			end
		end

		BUFFER2: begin
			hold = 1'b1;
			if (hwrite_reg == 1'b1) begin
				store_tx_data = 1'b1;
				tx_data = hwdata[23:16];
			end
			else begin
				get_rx_data = 1'b1;
				rx_data_next = {rx_data_reg[31:24], rx_data, rx_data_reg[15:0]};
			end
		end


		BUFFER1: begin
			hold = 1'b1;
			if (hwrite_reg == 1'b1) begin
				store_tx_data = 1'b1;
				tx_data = hwdata[31:24];
			end
			else begin
				get_rx_data = 1'b1;
				rx_data_next = {rx_data, rx_data_reg[23:0]};
			end
		end
	endcase
end


always_comb
begin: FLUSH_BUFFER_CONTROL_STATE_MACHINE_NEXT_STATE_LOGIC

  clear_buffer_control = 1'b0; 
  clear = 1'b0; 

  case(buffState)

  	TRANSFER: begin 

  		clear = 1'b1; 
  		clear_buffer_control = 1'b1; 

  	end 
  endcase // buffState
end


/*REGISTER MODULE CODE */
always_ff @ (posedge clk, negedge n_rst)
begin: REGISTER_LOGIC
	// if reset negation is applied
	if (1'b0 == n_rst ) begin
    	status_reg <= 'd0;
    	error_reg <= 'd0;
    	buffer_occup_reg <= 'd0;
    	tx_control_reg <= 'd0;
    	flush_buff_reg <= 'd0;
    	rx_data_reg <= 'd0
	end
	else begin
    	status_reg <= status_reg_next
	    error_reg <= error_reg_next;
	    buffer_occup_reg <= buffer_occupancy;
	    tx_control_reg <= tx_control_reg_next;
	    flush_buff_reg <= flush_buffer_reg_next;
	    rx_data_reg <= rx_data_next;
	end
end

always_ff @ (posedge clk, negedge n_rst)
begin: FLUSH_BUFFER_CONTROL_STATE_MACHINE_REGISTER
	// if reset negation is applied
	if (1'b0 == n_rst ) begin

    	buffState <= IDLE;

	end
	else begin

    	buffState <= buffStateNext; 

	end
end

always_ff @ (posedge clk, negedge n_rst)
begin: DATA_BUFFER_STATE_REGISTER_LOGIC
	// if reset negation is applied
	if (1'b0 == n_rst ) begin
    	data_state_reg <= IDLE;
	end
	else begin
    	data_state_reg <= data_state_next;
	end
end

endmodule // value_registers
