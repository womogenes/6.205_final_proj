`default_nettype none

module sd_reader #(
  parameter CLK_FREQ = 100_000_000
) (
  input  wire         clk,        // system clock
  input  wire         rst,
  
  // control
  input  wire         trigger,    // pulse to start read of block_addr
  input  wire [22:0]  block_addr, // block index (23 bits, lower 7 are all 0s)
  output logic        ready,

  // byte stream out
  output logic [7:0]  byte_out,
  output logic        byte_valid, // single-cycle pulse when byte_out is valid

  // SPI pins (to top-level IO)
  output logic        copi,
  input  wire         cipo,
  output logic        dclk,       // same as dclk
  output logic        cs         // chip select (active low)
);
  localparam START_DCLK_PERIOD = 512;
  localparam READ_DCLK_PERIOD = 4;
  // FSM states
  typedef enum {
    BOOT, // lasts LONG time (80 slow cycles)
    CARD_RESET, // lasts 8 bytes (6 CMD0, 1 R1, 1 WAIT)
    INTERFACE_CHECK, // lasts 11 bytes (6 CMD8, 5 R7)
    INIT_LOOP, // lasts 17 bytes (1 WAIT, 6 CMD55, 1 R1, 1 WAIT, 6 ACMD41, 1 R1, 1 WAIT)
    READY, // lasts indefinitely
    CMD, // lasts 7 bytes (6 CMD17, 1 R1)
    WAIT, // lasts unkown # of bytes (? 0xFF, 1 0xFE)
    READ // lasts 514 bytes (512 DATA, 2 CRC)
  } sd_reader_state;

  sd_reader_state state;
  assign ready = state == READY;
  logic [47:0] cmd;

  // SPI controller sub-module trackers
  logic [$clog2(START_DCLK_PERIOD) - 1:0] dclk_counter; // counter for flips of dclk
  logic [2:0] dclk_cycles; // counter for dclk cycles, keeps track of bits exchanged
  logic [9:0] byte_count; // counter for how many bytes have been exchanged

  // logic to check if current byte finished (send/receive)
  logic byte_finished;
  always_comb begin
    if (state == BOOT || state == CARD_RESET || state == INTERFACE_CHECK || state == INIT_LOOP) begin
      byte_finished = (dclk_counter == START_DCLK_PERIOD - 1) &&
        (dclk_cycles == 7);
    end else if (state == CMD || state == WAIT || state == READ) begin
      byte_finished = (dclk_counter == READ_DCLK_PERIOD - 1) &&
        (dclk_cycles == 7);
    end else begin
      byte_finished = 0;
    end
  end

  logic trigger_spi; // combinational SPI interface variable
  logic spi_dclk_mode; // combinational SPI interface variable
  logic [7:0] spi_data_out; // SPI output interface variable
  logic spi_data_valid; // SPI output interface variable
  logic [7:0] spi_data_buffer; // register for storing SPI output
  logic response_received;

  spi_con_continuous #(
    .DATA_WIDTH(8),
    .START_DCLK_PERIOD(START_DCLK_PERIOD),
    .READ_DCLK_PERIOD(READ_DCLK_PERIOD)
  ) spi_con (
    .clk(clk),
    .rst(rst),
    .dclk_mode_in(spi_dclk_mode),
    .data_in(cmd[47:40]),
    .trigger(trigger_spi),
    .data_out(spi_data_out),
    .data_valid(spi_data_valid),

    .copi(copi),
    .cipo(cipo),
    .dclk(dclk),
    .cs(cs)
  );

  assign spi_dclk_mode = (
    state == READY || 
    state == CMD || 
    state == WAIT || 
    state == READ);

  always_ff @(posedge clk) begin
    if (rst) begin
      // reset everything
      state <= BOOT;
      cmd <= 0;

      // I/O registers
      spi_data_buffer <= 0;
      byte_out <= 0;
      byte_valid <= 0;

      response_received <= 0;

      // SPI DCLK counters
      trigger_spi <= 0;
      dclk_counter <= 0;
      dclk_cycles <= 0;
      byte_count <= 0;

    end else begin
      // state machine transitions
      case (state)
        BOOT: begin // system has been reset, reset sd reader
          if (byte_finished) begin
            if (byte_count == 80) begin
              state <= CARD_RESET;
              cmd <= 48'h40_00_00_00_00_95; // CMD0

              dclk_counter <= 0;
              dclk_cycles <= 0;
              byte_count <= 0;
              trigger_spi <= 1;
            end else begin
              byte_count <= byte_count + 1;
            end
          end
        end
        CARD_RESET: begin
          if (byte_finished) begin
            if (response_received) begin // has already sent CMD0 and received R1
              state <= INTERFACE_CHECK;
              cmd <= 48'h48_00_00_01_AA_87; // CMD55

              byte_count <= 0;
              response_received <= 0;
            end else begin
              // move to next byte in command
              cmd <= {cmd[39:0], 8'h00};
              // increment byte counter
              byte_count <= byte_count + 1;
              if (byte_count > 6 && spi_data_buffer != 8'hFF) begin
                response_received <= 1;
              end
            end
            trigger_spi <= ~response_received;
          end
        end
        INTERFACE_CHECK: begin
          if (byte_finished) begin
            if (response_received && byte_count == 5) begin // has already send CMD8, received R7
              state <= INIT_LOOP;

              byte_count <= 0;
              response_received <= 0;
            end else begin
              // move to next byte in command
              cmd <= {cmd[39:0], 8'h00};
              // increment byte counter
              byte_count <= byte_count + 1;
              if (byte_count > 6 && spi_data_buffer != 8'hFF) begin
                response_received <= 1;
              end
            end
            trigger_spi <= (~response_received || byte_count < 5);
          end
        end
        INIT_LOOP:  begin
          if (byte_finished) begin
            if (byte_count == 0) begin
              cmd <= 48'h77_00_00_00_00_65; // CMD55

              byte_count <= byte_count + 1;
            end else if (byte_count == 8) begin
              cmd <= 48'h69_40_00_00_00_77; // ACMD41

              byte_count <= byte_count + 1;
            end else if (byte_count == 16) begin
              // check R1 of ACMD41
              if (spi_data_buffer == 8'h00) begin
                state <= READY;
              end else begin
                state <= INIT_LOOP;
              end
              byte_count <= 0;
            end else begin
              // move to next byte in command
              cmd <= {cmd[39:0], 8'h00};
              // increment byte counter
              byte_count <= byte_count + 1;
            end
            trigger_spi <= ~(byte_count == 7 || byte_count == 15 || byte_count == 16);
          end else begin
            trigger_spi <= 0;
          end
        end
        READY: begin
          if (trigger) begin
            state <= CMD;
            cmd <= {8'h51, block_addr, 9'b0, 8'hFF};
            trigger_spi <= 1;
          end else begin
            trigger_spi <= 0;
          end
        end
        CMD: begin
          if (byte_finished) begin
            if (byte_count == 6) begin
              //transition to waiting period
              state <= WAIT;
              byte_count <= 0; 
            end else begin
              // move to next byte in command
              cmd <= {cmd[39:0], 8'h00};
              // increment byte counter
              byte_count <= byte_count + 1;
            end
            trigger_spi <= 1;
          end else begin
            trigger_spi <= 0;
          end
        end
        WAIT: begin
          if (byte_finished) begin
            // previous "wait" cycle was actually data
            if (spi_data_buffer == 8'hFE) begin
              state <= READ;
            end
            trigger_spi <= 1;
          end else begin
            trigger_spi <= 0;
          end
        end
        READ: begin
          // technically output previous byte
          if (byte_finished) begin
            if (byte_count == 513) begin
              state <= READY;
              byte_count <= 0;
            end else begin
              byte_out <= spi_data_buffer;
              byte_valid <= ~(byte_count == 512);
              byte_count <= byte_count + 1;
            end
            trigger_spi <= ~(byte_count == 513);
          end else begin
            trigger_spi <= 0;
            byte_valid <= 0;
          end
        end
      endcase

      // dclk cycle tracker
      if (state == BOOT || state == CARD_RESET || state == INTERFACE_CHECK || state == INIT_LOOP) begin
        // finished a bit
        if (dclk_counter == START_DCLK_PERIOD - 1) begin
          dclk_counter <= 0;
          // finished a byte
          if (dclk_cycles == 7) begin
            // reset bit counter
            dclk_cycles <= 0;
            // finished_bit should be true here
          end else begin
            dclk_cycles <= dclk_cycles + 1;
          end
        end else begin
          dclk_counter <= dclk_counter + 1;
        end
      end else if (state == CMD || state == WAIT || state == READ) begin
        if (dclk_counter == READ_DCLK_PERIOD - 1) begin
          dclk_counter <= 0;
          // finished a byte
          if (dclk_cycles == 7) begin
            // reset bit counter
            dclk_cycles <= 0;
            // finished_bit should be true here
          end else begin
            dclk_cycles <= dclk_cycles + 1;
          end
        end else begin
          dclk_counter <= dclk_counter + 1;
        end
      end else begin
        dclk_counter <= 0;
        dclk_cycles <= 0;
      end

      // SPI response data capture
      if (spi_data_valid) begin
        spi_data_buffer <= spi_data_out;
      end
    end
  end

endmodule

`default_nettype wire
