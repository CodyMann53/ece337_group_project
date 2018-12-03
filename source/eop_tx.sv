// $Id: $
// File name:   eop.sv
// Created:     12/1/2018
// Author:      Alexandra Fyffe
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: End of Packet Detection

module eop_detect
(
	input wire d_plus,
	input wire d_minus,
	output wire eop
);

	assign eop = (!d_plus) && (!d_minus);

endmodule
