`default_nettype none

module sd_reader #(
  parameter CLK_FREQ = 100_000_000
) (
  input  logic        clk,        // system clock
  input  logic        rst,
  
  // control
  input  logic        trigger,    // pulse to start read of block_addr
  input  logic [22:0] block_addr, // block index (23 bits, lower 7 are all 0s)
  output logic        busy,

  // byte stream out
  output logic [7:0]  byte_out,
  output logic        byte_valid, // single-cycle pulse when byte_out is valid

  // SPI pins (to top-level IO)
  output logic        cs,         // chip select (active low)
  output logic        dclk,       // same as dclk
  output logic        copi,
  input  logic        cipo
);
  localparam START_DCLK_PERIOD = 1000;
  localparam READ_DCLK_PERIOD = 4;
  // FSM states
  typedef enum {
    BOOT,
    CARD_RESET,
    INTERFACE_CHECK,
    INIT_LOOP,
    READY,
    CMD,
    WAIT,
    READ
  } sd_reader_state;

  sd_reader_state state;

  // SPI controller sub-modules
  logic [$clog2(START_DCLK_PERIOD / 2) - 1:0] dclk_counter; // counter for flips of dclk
  logic [2:0] dclk_cycles; // counter for dclk cycles, keeps track of bits exchanged
  logic [9:0] byte_count; // counter for how many bytes have been exchanged

  logic [47:0] cmd;

  always_ff @(posedge clk) begin
    if (rst) begin
      // reset everything
      state <= BOOT;
      cmd <= 0;

    end else begin
      // state machine
      case (state)
        BOOT: begin // system has been reset, reset sd reader
          state <= CARD_RESET;
          cmd <= 48'h40_00_00_00_00_95;

          dclk_counter <= 0;
          dclk_cycles <= 0;
          byte_count <= 0;
        end
        CARD_RESET: begin
          // finished a bit
          if (dclk_counter == START_DCLK_PERIOD - 1) begin
            dclk_counter <= 0;
            // finished a byte
            if (dclk_cycles == 7) begin
              // reset bit counter
              dclk_cycles <= 0;
              // start command has been fully sent (6 bytes + 1 response byte)
              if (byte_count == 6) begin
                state <= INTERFACE_CHECK;
                cmd <= 48'h48_00_00_01_AA_87;

                byte_count <= 0;
              end else begin
                // move to next byte in command
                cmd <= {cmd[39:0], 8'h00};
                // increment byte counter
                byte_count <= byte_count + 1;
              end
            end else begin
              dclk_cycles <= dclk_cycles + 1;
            end
          end else begin
            dclk_counter <= dclk_counter + 1;
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
