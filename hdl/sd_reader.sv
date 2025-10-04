`default_nettype none

module sd_spi_con #(
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

  // FSM states
  typedef enum {
    IDLE,
    INTERFACE_CHECK,
    INIT_LOOP,
    READY,
    READING
  } sd_spi_con_state;

  sd_spi_con_state state;

  // IO with SD card
  logic [47:0] cmd;
  logic [31:0] dclk_subcounter;
  logic [31:0] dclk_counter;      // TODO: can maybe decrease width

  always_ff @(posedge clk) begin
    if (rst) begin
      // reset everything
      cs_n <= 0;
      dclk <= 0;
      byte_out <= 0;
      byte_valid <= 0;

    end else begin
      // state machine
      case (state)
        IDLE: begin
          // send CMD0 until we read 0x01
          // 100 kHz in this mode
          // CMD0 is 0x40 00 00 00 00 95
          dclk_counter <= 0;
          dclk_subcounter <= 0;

        end
      endcase
    end
  end

endmodule

`default_nettype wire
