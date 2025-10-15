`default_nettype none

module spi_con_continuous #(
  parameter DATA_WIDTH = 8,
  parameter START_DCLK_PERIOD = 1000,
  parameter READ_DCLK_PERIOD = 4
    ) ( 
    input wire   clk, //system clock (100 MHz)
    input wire   rst, //reset in signal
    input wire   dclk_mode_in, // input for dclk period
    input wire   [DATA_WIDTH-1:0] data_in, //data to send
    input wire   trigger, //start a transaction
    output logic [DATA_WIDTH-1:0] data_out, //data received!
    output logic data_valid, //high when output data is present.

    output logic copi, //(Controller-Out-Peripheral-In)
    input  wire  cipo, //(Controller-In-Peripheral-Out)
    output logic dclk, //(Data Clock)
    output logic cs // (Chip Select)

  );

  typedef enum {
    IDLE,
    ACTIVE
  } sd_spi_state;

  parameter integer START_DCLK_HALF_PERIOD = $floor(START_DCLK_PERIOD / 2);
  parameter integer READ_DCLK_HALF_PERIOD = $floor(READ_DCLK_PERIOD / 2);
  logic dclk_mode; // count fast or slow (0 for start, 1 for read)
  logic [$clog2(START_DCLK_HALF_PERIOD) - 1: 0] dclk_counter;
  logic [DATA_WIDTH - 1: 0] data_out_buffer;
  logic [DATA_WIDTH - 1: 0] data_in_buffer;
  logic [$clog2(DATA_WIDTH + 1) - 1: 0] dclk_cycles;
  sd_spi_state state;

  always_ff @(posedge clk) begin
  if (rst) begin
    // reset chip select 
    cs <= 1'b1;
    state <= IDLE;
    // reset dclk
    dclk_mode <= 0;
    dclk <= 0;
    dclk_counter <= 0;
    dclk_cycles <= 0;
    // reset output to peripheral
    data_in_buffer <= 0;
    copi <= 1;
    // reset output to controller
    data_out_buffer <= 0;
    data_valid <= 0;
    data_out <= 0;
  end else begin
    case (state)
      IDLE: begin
        if (dclk_counter == (dclk_mode ? 
          READ_DCLK_HALF_PERIOD - 1 : START_DCLK_HALF_PERIOD - 1)) begin
          //flip dclk
          dclk_counter <= 0;
          dclk <= ~dclk;
          if (dclk && trigger) begin
            // set chip select and state
            cs <= 1'b0;
            state <= ACTIVE;
            // latch data and start transmitting
            data_in_buffer <= {data_in[DATA_WIDTH - 2 : 0], 1'b0};
            copi <= data_in[DATA_WIDTH - 1];
            //start the dclk
            dclk_mode <= dclk_mode_in;
            dclk <= 1'b0;
            dclk_counter <= 0;
            dclk_cycles <= 0;
          end
          end else begin
            dclk_counter <= dclk_counter + 1;
          end
      end
      ACTIVE: begin
        if (dclk_counter == (dclk_mode ? 
          READ_DCLK_HALF_PERIOD - 1 : START_DCLK_HALF_PERIOD - 1)) begin
        //flip dclk
        dclk_counter <= 0;
        dclk <= ~dclk;
        if (~dclk) begin // rising edge
          data_out_buffer <= {data_out_buffer[DATA_WIDTH - 2:0], cipo};
          
        end else begin // falling edge
          // finish transaction
          if (dclk_cycles == DATA_WIDTH - 1) begin
            if (~trigger) begin // actual end of transaction
              cs <= 1'b1;
              state <= IDLE;
            end else begin // more data to be transmitted / received
              // need to read that more data and immediately start send
              data_in_buffer <= {data_in[DATA_WIDTH - 2 : 0], 1'b0};
              copi <= data_in[DATA_WIDTH - 1];
            end
            data_valid <= 1'b1;
            data_out <= data_out_buffer;
            dclk_cycles <= 0;
          end else begin // middle of transaction
            // output next bit and shift
            copi <= data_in_buffer[DATA_WIDTH - 1];
            data_in_buffer <= {data_in_buffer[DATA_WIDTH - 2 : 0], 1'b0};
            // increment total cycles completed
            dclk_cycles <= dclk_cycles + 1;
          end
        end
      end else begin
        dclk_counter <= dclk_counter + 1;
      end
      end
    endcase
    if (data_valid) begin
      data_valid <= 1'b0;
    end
  end
  end

endmodule

`default_nettype wire