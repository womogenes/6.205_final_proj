module spi_con_continuous
   #(parameter DATA_WIDTH = 8,
     parameter DATA_CLK_PERIOD = 100
    )
  ( input wire   clk, //system clock (100 MHz)
    input wire   rst, //reset in signal
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

  parameter integer ACTUAL_DCLK_PERIOD = $floor(DATA_CLK_PERIOD / 2) * 2;
  parameter integer ACTUAL_DCLK_HALF_PERIOD = $floor(ACTUAL_DCLK_PERIOD / 2);
  logic [$clog2(ACTUAL_DCLK_HALF_PERIOD) - 1: 0] dclk_counter;
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
    dclk <= 0;
    dclk_counter <= 0;
    dclk_cycles <= 0;
    // reset output to peripheral
    data_in_buffer <= 0;
    copi <= 0;
    // reset output to controller
    data_out_buffer <= 0;
    data_valid <= 0;
    data_out <= 0;
  end else begin
    case (state)
      IDLE: begin
        if (trigger) begin
          // set chip select and state
          cs <= 1'b0;
          state <= ACTIVE;
          // latch data and start transmitting
          data_in_buffer <= {data_in[DATA_WIDTH - 2 : 0], 1'b0};
          copi <= data_in[DATA_WIDTH - 1];
          //start the dclk
          dclk <= 1'b0;
          dclk_counter <= 0;
          dclk_cycles <= 0;
        end
      end
      ACTIVE: begin
        if (dclk_counter == ACTUAL_DCLK_HALF_PERIOD - 1) begin
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