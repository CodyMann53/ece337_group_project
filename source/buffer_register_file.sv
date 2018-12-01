// $Id: $
// File name:   buffer_register_file.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is the register file portion of data buffer module


module buffer_register_file(

  input wire clk,
  input wire n_rst,
  input wire [1:0] op,
  input wire [7:0] write_data,
  input wire [5:0] read_pointer,
  input wire [5:0] write_pointer,
  output reg [7:0] read_data
);

typedef enum logic [1:0] {NOP,
                          WRITE,
                          READ
                          }
							op_type_type;

op_type operation;
assign operation = op;

reg [7:0] buffer [63:0];
reg [7:0] buffer_next [63:0];

integer i;

always_comb
begin: STATE_NEXT_LOGIC

  // assigning arbitrary values to prevent latches
  read_data = 0;

  for (i=0; i < 64; i=i+1)
    buffer_next[i] <= buffer[i];

  // if a write operation
  if (operation == WRITE) begin
    // assign write data to memory location
    buffer_next[write_pointer] = write_data;
  else if (operation == READ)begin
    // assign memory location value to read data output
    read_data = buffer[read_pointer];

end

// register to hold buffer
always_ff @ (posedge clk, negedge n_rst)
begin: BUFFER_REGISTER_LOGIC
	// if reset negation is applied
	if (1'b0 == n_rst ) begin
		// reset all byte value back to zero
		for (i=0; i < 64; i=i+1)
      buffer[i] <= 8'd0;
	end
	else begin
    // set to next buffer value
    for (i=0; i < 64; i=i+1)
      buffer[i] <= buffer_next[i];
	end
end
endmodule // buffer_register_file