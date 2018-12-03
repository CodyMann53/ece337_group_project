// $Id: $
// File name:   ahb_slave_lite_usb.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the overarching module for the ahb lite slave module to be interfaced with usb recieving and transmitting devices.

module ahb_slave_lite_usb(

  input wire clk,
  input wire n_rst,
  input wire hsel, 
  input wire [3:0] haddr, 
  input wire [1:0] htrans, 
  input wire [1:0] hsize, 
  input wire hwrite, 
  input wire [31:0] hwdata, 
  output reg [31:0] hrdata, 
  output reg hresp, 
  output reg hready, 
  input wire [2:0] rx_packet, 
  input wire rx_data_ready, 
  input wire rx_transfer_active, 
  input wire rx_error, 
  output reg d_mode, 
  input wire [6:0] buffer_occupancy,
  input wire [7:0] rx_data, 
  output reg get_rx_data, 
  output reg store_tx_data, 
  output reg [6:0] tx_data, 
  output reg clear, 
  output reg [1:0] tx_packet, 
  input wire tx_transfer_active, 
  input wire tx_error
);

/* parameter definitions */
parameter [1:0] {IDLE = 2'd0,
                 DATA_TRANSFER = 2'd1, 
                 ERROR = 2'd2;}

reg [1:0] state, nextState; 


/*INTERNAL SIGNAL DEFINITIONS */
reg [1:0] hsize_reg; 
reg [3:0] haddr_reg; 
reg hwrite_reg; 
reg [3:0] value_location; 

/* WRAPPER DEFINITIONS */
address_decoder DECODER(.haddr_reg(haddr_reg), 
						.hsize_reg(hsize_reg), 
						.value_location(value_location)
						); 

value_registers VAL_REG(.clk(clk), 
						.n_rst(n_rst), 
						.val_loc(value_location),
						.hwrite_reg(hwrite_reg), 
						.hwdata(hwdata),
						.state(state), 
						.rx_packet(rx_packet), 
						.rx_data_ready(rx_data_ready),
						.rx_transfer_active(rx_transfer_active), 
						.rx_error(rx_error), 
						.buffer_occupancy(buffer_occupancy), 
						.rx_data(rx_data), 
						.tx_transfer_active(tx_transfer_active), 
						.tx_error(tx_error), 
						.d_mode(d_mode), 
						.get_rx_data(get_rx_data), 
						.store_tx_data(store_tx_data), 
						.tx_data(tx_data), 
						.tx_packet(tx_packet), 
						.clear(clear),
						.hrdata(hrdata), 
						.hold(hold)
						); 

/* STATE_MACHINE_CODE */
always_comb
begin: NEXT_STATE_LOGIC

	nextState = state; 

	case(state)

		IDLE: begin 
			if (haddr > 4'hD) begin
				nextState = ERROR; 
			end
			else if ( (haddr > 4'h8) & (haddr < 4'hC) ) begin
				nextState = ERROR;
			end 
			else if ((hsel == 1'b1) & (htrans == 2'd2)) begin 
				nextState = DATA_TRANSFER; 
			end 
			else if ((hsel == 1'b0) | (htrans == 2'd0)) begin 
				nextState = IDLE;
			end 
		end 

		DATA_TRANSFER: begin 
			if ((hsel == 1'b1) & (haddr < 4'hD)) begin 
				nextState = DATA_TRANSFER; 
			end 
			else if (  ( (hsel == 1'b0) | (htrans == 2'd0) )  & (haddr <= 4'hD) ) begin 
				nextState = IDLE; 
			end 
			else begin 
				nextState = ERROR; 
			end 
		end 

		ERROR: begin 
			nextState = IDLE; 
		end 
	endcase
end

always_comb
begin: ERROR_OUTPUT_LOGIC

	hresp = 1'b0; 
	hready = 1'b0; 

	case(state)

		IDLE: begin 
			if (haddr > 4'hD) begin 
				hresp = 1'b1; 
				hready = 1'b0; 
			end 
			else if (hwrite == 1'b1) begin 
				if ( (haddr >= 4'h4 ) & (haddr < 4'hC)) begin 
					hresp = 1'b1; 
					hready = 1'b0; 
				end 
			end 
			else if ( (haddr > 4'h8) & (haddr < 4'hC)) begin 
					hready = 1'b0; 
					hresp = 1'b1; 
			end 
		end 

		DATA_TRANSFER: begin  
			if (hold == 1'b1) begin 
				hready = 1'b1; 
			end 
			else begin 
				hresp = 1'b1; 
				hready = 1'b1; 
			end 
		end 
	endcase
end

/* REGISTER LOGIC */
always_ff @ (posedge clk, negedge n_rst)
begin: HSIZE_REGISTER_
	if (1'b0 == n_rst ) begin
    	hsize_reg <= 2'd0;
	end
	else begin
    	hsize_reg <= hsize; 
	end
end

always_ff @ (posedge clk, negedge n_rst)
begin: HADDR_REGISTER_
	if (1'b0 == n_rst ) begin
    	haddr_reg <= 4'd0;
	end
	else begin
    	haddr_reg <= haddr; 
	end
end

always_ff @ (posedge clk, negedge n_rst)
begin: HWRITE_REGISTER_
	if (1'b0 == n_rst ) begin
    	hwrite_reg <= 1'd0;
	end
	else begin
    	hwrite_reg <= hwrite; 
	end
end

always_ff @ (posedge clk, negedge n_rst)
begin: STATE_REGISTER_LOGIC
	if (1'b0 == n_rst ) begin
    	state <= IDLE;
	end
	else begin
    	state <= nextState; 
	end
end

endmodule // ahb_slave_lite_usb