// Description: Flexible counter with roll over flag
module flex_counter
#(
	parameter NUM_CNT_BITS = 4
)
(
	input wire clk, // The system clock. (Maximum Operating Frequency: 1Ghz.
	input wire n_rst, // This is an asynchronous, active-low system reset. When this line is asserted (logic '0'), all registers/flip-flops in the device must reset to their initial value.
	input wire clear, // This is the active-high signal that forces the counter to synchronously clear its current count value back to 0.
	input wire count_enable, //This is the active-high enable signal that allows the counter to increment its internal value
	input wire [(NUM_CNT_BITS - 1):0] rollover_val, // This is the N-bit value that is checked against for determining when to rollover.
	output reg [(NUM_CNT_BITS - 1):0] count_out, // This is the current N-bit count value stored in the counter.
	output reg rollover_flag
);

reg [(NUM_CNT_BITS - 1):0] next_count;
reg next_rollover;


// combinational block to determine next counter value based on clear, enable, and rollover inputs
always_comb
begin: NEXT_LOGIC

	// assigning arbitrary value
	next_count = count_out;

	if ( clear == 1'b1) begin 

		// reset values back to zero 
		next_count = 0; 

	end 
	else if ( count_enable == 1'b1 ) begin 

		// if reached rollover value 
		if ( count_out == rollover_val) begin 

			// reset back to one 
			next_count = 'd1; 

		end
		else begin 

			// increment counter
			next_count = count_out + 1; 

		end 

	end 
	else if ( count_enable == 1'b0) begin 

			

			// stay put 
			next_count = count_out;

	end

end

always_comb
begin: ROLLOVER_NEXT_LOGIC

	// assigning arbitrary values
	next_rollover = 1'b0;

	// if clearing 
	if ( clear == 1'b1) begin 

		next_rollover = 1'b0; 

	end 
	else if ( count_enable == 1'b1) begin 

		if ( count_out == (rollover_val - 1) ) begin 

			next_rollover = 1'b1; 

		end

	end 
	else if ( count_enable == 1'b0) begin 

		if ( count_out == (rollover_val) ) begin 

			next_rollover = 1'b1; 

		end 

	end 

end 

// register to hold rollover flag
always_ff @ (posedge clk, negedge n_rst)
begin: ROLLOVER_REG_LOGIC


	// if reset negation is applied
	if (1'b0 == n_rst ) begin

		// reset all flip flops to zeros
		rollover_flag <= 0;

	end
	else begin

		// don't set flag
		rollover_flag <= next_rollover;

	end

end

// register to hold counter value
always_ff @ (posedge clk, negedge n_rst)
begin: COUNT_REG_LOGIC


	// if reset negation is applied
	if (1'b0 == n_rst ) begin

		// reset all flip flops to zeros
		count_out <= 0;


	end
	else begin

		// set value to next_count
		count_out <= next_count;
	end
end

endmodule
