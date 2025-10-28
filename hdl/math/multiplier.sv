`default_nettype none
module multiplier #(
  parameter WIDTH_A = 16,
  parameter WIDTH_B = 16,
  parameter BITS_DROPPED = 16
) (
  input wire rst,
  input wire clk,

  input wire [WIDTH_A - 1:0] din_a,
  input wire [WIDTH_B - 1:0] din_b,
  input wire din_valid,

  output logic [WIDTH_A + WIDTH_B - BITS_DROPPED - 1:0] dout,
  output logic dout_valid
);

  logic [WIDTH_A + WIDTH_B - 1:0] prod;
  assign prod = din_a * din_b;

  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= 0;
      dout_valid <= 0;
    end else begin
      dout <= prod[WIDTH_A + WIDTH_B - 1:BITS_DROPPED];
      dout_valid <= din_valid;
    end
  end
    
endmodule
`default_nettype wire