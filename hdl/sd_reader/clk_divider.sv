`default_nettype none

module clk_divider (
  input wire clk_100mhz,
  input wire rst,
  output logic clk_25mhz,  // single-cycle valid output on 25 MHz
  output logic clk_195khz // single-cycle valid output at ~195 kHz
);
  logic [8:0] counter;

  always_ff @(posedge clk_100mhz) begin
    if (rst) begin
      counter <= 0;
    end else begin
      counter <= (counter == 511) ? 0 : counter + 1;
    end
  end

  assign clk_25mhz = counter[1:0] == 2'b11;
  assign clk_195khz = counter[8:0] == 9'b1_1111_1111;
endmodule

`default_nettype wire
