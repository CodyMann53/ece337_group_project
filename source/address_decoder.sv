// $Id: $
// File name:   address_decoder.sv
// Created:     11/27/2018
// Author:      Cody Mann
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: This is a simple address decoder for the ahp lite slave module

module address_decoder(

  input wire [3:0] haddr_reg,
  input wire [1:0] hsize_reg,
  output wire [3:0] value_location
);

// declaring buffer location signals to send as an output 
parameter [3:0] {BUFFER4 = 4'd0, 
                 BUFFER3 = 4'd1, 
                 BUFFER2 = 4'd2, 
                 BUFFER1 = 4'd3, 
                 STATUS  = 4'd4, 
                 STATUS_LOWER = 4'd5, 
                 STATUS_UPPER = 4'd6, 
                 ERROR = 4'd7, 
                 ERROR_LOWER = 4'd8,
                 ERROR_UPPER = 4'd9,
                 TX_CONTROL = 4'd10,
                 FLUSH_BUFFER = 4'd11, 
                 BUFFER_OCCUP = 4'd12}; 



always_comb
begin: OUTPUT_LOGIC

  //creating arbitrary to prevent latches
  value_location= ERROR;

  case (haddr_reg)

    4'h0: begin
      if(hsize_reg >= 4) begin
        value_location= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        value_location= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        value_location= BUFFER2;
      end
      else begin
        value_location= BUFFER1;
      end
    end

    4'h1: begin
      if(hsize_reg >= 4) begin
        value_location= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        value_location= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        value_location= BUFFER2;
      end
      else begin
        value_location= BUFFER1;
      end
    end

    4'h2: begin
      if(hsize_reg >= 4) begin
        value_location= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        value_location= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        value_location= BUFFER2;
      end
      else begin
        value_location= BUFFER1;
      end
    end

    4'h3: begin
      if(hsize_reg >= 4) begin
        value_location= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        value_location= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        value_location= BUFFER2;
      end
      else begin
        value_location= BUFFER1;
      end
    end

    4'h4: begin
      if( hsize_reg >= 2) begin
        value_location= STATUS;
      end
      else begin
        value_location = STATUS_LOWER;
      end
    end

    4'h5: begin
      if (hsize_reg >= 2) begin
        value_location= STATUS;
      end
      else begin
        value_location= STATUS_UPPER;
      end
    end

    4'h6: begin
      if (hsize_reg >= 2) begin
        value_location= ERROR;
      end
      else begin
        value_location= ERROR_LOWER;
      end
    end

    4'h7: begin
      if (hsize_reg >= 2) begin
        value_location= ERROR;
      end
      else begin
        value_location= ERROR_UPPER;
      end
    end

    4'h8: begin
      value_location = BUFFER_OCCUP;
    end

    4'hC: begin
      value_location= TX_CONTROL;
    end

    4'hD: begin
      value_location= FLUSH_BUFFER;
    end
  endcase
end

endmodule // address_decoder