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
                          FLUSH_BUFFER
                        }
						location_type;

location_type val_loc;
assign value_location = val_loc;

always_comb
begin: OUTPUT_LOGIC

  //creating arbitrary to prevent latches
  val_loc= ERROR;

  case (haddr_reg)

    4'h0: begin
      if(hsize_reg >= 4) begin
        val_loc= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        val_loc= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        val_loc= BUFFER2;
      end
      else begin
        val_loc= BUFFER1;
      end
    end

    4'h1: begin
      if(hsize_reg >= 4) begin
        val_loc= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        val_loc= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        val_loc= BUFFER2;
      end
      else begin
        val_loc= BUFFER1;
      end
    end

    4'h2: begin
      if(hsize_reg >= 4) begin
        val_loc= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        val_loc= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        val_loc= BUFFER2;
      end
      else begin
        val_loc= BUFFER1;
      end
    end

    4'h3: begin
      if(hsize_reg >= 4) begin
        val_loc= BUFFER4;
      end
      else if (hsize_reg == 3) begin
        val_loc= BUFFER3;
      end
      else if (hsize_reg == 2) begin
        val_loc= BUFFER2;
      end
      else begin
        val_loc= BUFFER1;
      end
    end

    4'h4: begin
      if( hsize_reg >= 2) begin
        value_locaiton = STATUS;
      end
      else begin
        value_locaiton = STATUS_LOWER;
      end
    end

    4'h5: begin
      if (hsize_reg >= 2) begin
        val_loc= STATUS;
      end
      else begin
        val_loc= STATUS_UPPER;
      end
    end

    4'h6: begin
      if (hsize_reg >= 2) begin
        val_loc= ERROR
      end
      else begin
        val_loc= ERROR_LOWER;
      end
    end

    4'h7: begin
      if (hsize_reg >= 2) begin
        val_loc= ERROR;
      end
      else begin
        val_loc= ERROR_UPPER;
      end
    end

    4'h8: begin
      value_locaiton = BUFFER_OCCUP;
    end

    4'hC: begin
      val_loc= TX_CONTROL;
    end

    4'hD: begin
      val_loc= FLUSH_BUFFER;
    end
  endcase
end

endmodule // address_decoder