`timescale 1ns / 1ps
`default_nettype none
 
module uart_receive
#(
  parameter INPUT_CLOCK_FREQ = 100_000_000,
  parameter BAUD_RATE = 115200
)
(
  input wire 	       clk,
  input wire 	       rst,
  input wire 	       din,
  output logic       dout_valid,
  output logic [7:0] dout
);
  localparam integer BAUD_BIT_PERIOD = $ceil(INPUT_CLOCK_FREQ / BAUD_RATE);
  localparam integer LOG2_BAUD_BIT_PERIOD = $clog2(BAUD_BIT_PERIOD);
 
  typedef enum {
    IDLE = 0,
    START = 1,
    DATA = 2,
    STOP = 3,
    TRANSMIT = 4
  } uart_state;
 
  // note: for the online checker, don't rename this variable
  uart_state state;

  logic [4:0] bit_counter;
  logic [LOG2_BAUD_BIT_PERIOD-1:0] bit_subcounter;

  always_ff @(posedge clk) begin
    // useful wire to have
    logic is_mid_period;
    logic reset_bit_subcounter;
    logic reset_bit_counter;

    is_mid_period = bit_subcounter == (BAUD_BIT_PERIOD >> 1) - 1;

    if (rst) begin
      // reset everything
      state <= IDLE;
      dout_valid <= 0;
      dout <= 0;
      bit_counter <= 0;
      bit_subcounter <= 0;
      dout <= 0;

    end else begin
      reset_bit_counter = 1'b0;
      reset_bit_subcounter = 1'b0;
      
      case (state)
        IDLE: begin
          // detect zero? go to start
          if (din == 1'b0) begin
            state <= START;
          end else begin
            reset_bit_counter = 1'b1;
            reset_bit_subcounter = 1'b1;
          end
        end
        START: begin
          // wait for subcounter to reach half period
          if (is_mid_period) begin
            case (din)
              1'b0: begin
                state <= DATA; // good start bit!
              end
              1'b1: begin
                state <= IDLE; // bad start bit, reset
                reset_bit_counter = 1'b1;
                reset_bit_subcounter = 1'b1;
              end
            endcase
          end
        end
        DATA: begin
          if (bit_counter == 8 && bit_subcounter == BAUD_BIT_PERIOD - 1) begin
            // go to stop
            state <= STOP;

          end else if (is_mid_period) begin
            // we should be in bits 1 through 8, sample at middle
            // reading real data
            dout <= {din, dout[7:1]};
          end
        end
        STOP: begin
          // bit_counter should be 9
          // verify end bit
          if (is_mid_period) begin
            case (din)
              1'b1: begin
                state <= TRANSMIT;
                dout_valid <= 1;
              end
              1'b0: state <= IDLE;
            endcase

            // reset anyways
            reset_bit_counter = 1'b1;
            reset_bit_subcounter = 1'b1;
          end
        end
        TRANSMIT: begin
          // dout_valid should be high for one cycle
          // prep a reset
          dout_valid <= 1'b0;
          dout <= 0;
          state <= IDLE;
          reset_bit_counter = 1'b1;
          reset_bit_subcounter = 1'b1;
        end
      endcase

      // Handle resetting bit counter/subcounter
      if (reset_bit_counter) begin
        bit_counter <= 0;
      end else begin
        // next uart bit
        // assume we're in the data region
        //   if we're at the end then reset_bit_counter will be true
        if (bit_subcounter == BAUD_BIT_PERIOD - 1) begin
          reset_bit_subcounter = 1'b1;
          bit_counter <= bit_counter + 1;
        end
      end
      
      if (reset_bit_subcounter) begin 
        bit_subcounter <= 0;
      end else begin
        bit_subcounter <= bit_subcounter + 1;
      end
    end
  end
 
endmodule
 
`default_nettype wire
