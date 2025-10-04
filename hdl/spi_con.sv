module spi_con #(
    parameter DATA_WIDTH = 8,
    parameter DATA_CLK_PERIOD = 100
) (
    input  wire  clk, // system clock (100 MHz)
    input  wire  rst, // reset in signal
    input  wire  [DATA_WIDTH-1:0] data_in, // data to send
    input  wire  trigger, // start a transaction
    output logic [DATA_WIDTH-1:0] data_out, // data received!
    output logic data_valid, // high when output data is present.

    output logic copi, // (Controller-Out-Peripheral-In)
    input  wire  cipo, // (Controller-In-Peripheral-Out)
    output logic dclk, // (Data Clock)
    output logic cs // (Chip Select)
);
    // transmitting register
    logic is_transmitting = 0;
  
    // latch to grab data_in
    logic [DATA_WIDTH-1:0] data_in_reg = 0;

    // state tracking
    logic [31:0] dclk_counter;      // data bit
    logic [31:0] dclk_subcounter;   // tracks sys_clk

    logic new_bit;

    // initialization (trigger detection)
    always_ff @(posedge clk) begin
        new_bit = 0;

        // reset trigger
        if (rst) begin
            cs = 1;
            dclk_counter <= 0;
            dclk_subcounter <= 1;
            is_transmitting <= 0;
            data_valid <= 0;
            dclk <= 0;
            copi = 0;
            data_out = 0;

        end else begin
            // NOT being resetted

            // reset data_valid always (only on for one clock cycle)
            if (data_valid) begin
                data_valid <= 0;
            end

            // if triggered, start transmitting
            if (~is_transmitting && trigger) begin
                is_transmitting <= 1'b1;
                data_in_reg <= data_in;
                
                dclk_counter <= 0;
                dclk_subcounter <= 1;

                new_bit = 1'b1;
                dclk = 0;
                cs = 0;

            end else if (is_transmitting) begin
                // also have new bit on LOW transition of dclk
                // happens when dclk_subcounter hits 2*DATA_CLK_PERIOD
                if (dclk_subcounter == DATA_CLK_PERIOD) begin

                    // BUT WAIT, ARE WE DONE?
                    if (dclk_counter == DATA_WIDTH-1) begin
                        // end transmission
                        is_transmitting <= 0;
                        cs = 1'b1;
                        data_valid <= 1'b1;
                        dclk = 0;
                        dclk_counter <= 0;
                        new_bit = 1;
                        dclk_subcounter <= 1;

                    end else begin
                        // new bit
                        new_bit = 1'b1;
                        dclk_subcounter <= 1;
                        dclk_counter <= dclk_counter + 1;
                        data_in_reg <= data_in_reg << 1;
                        dclk = 0;
                    end

                end else begin
                    // middle of signal, don't worry about it
                    dclk_subcounter <= dclk_subcounter + 1;

                    // update dclk signal if needed
                    if (dclk_subcounter == (DATA_CLK_PERIOD >> 1)) begin
                        dclk = 1;
                    end
                end
            end

            // okay if we have a new bit we should read it and prep a shift
            // OR if we're at the very end
            if (new_bit && is_transmitting) begin
                // read in data (to data_out)
                data_out <= {data_out[DATA_WIDTH-2:0], cipo};
            end
            
            copi = data_in_reg[DATA_WIDTH-1];
        end
    end
  
endmodule
