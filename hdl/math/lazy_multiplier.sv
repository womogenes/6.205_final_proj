`default_nettype none
module lazy_multiplier #(
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

  logic [WIDTH_A - 1:0][WIDTH_A + WIDTH_B - BITS_DROPPED - 1:0] truncs;
  logic [WIDTH_A + WIDTH_B - BITS_DROPPED - 1:0] sum;

  always_comb begin
    sum = 0;
    for (integer i = 0; i < WIDTH_A; i = i + 1) begin
      if (BITS_DROPPED - i > 0) begin
        truncs[i] = (din_b >> (BITS_DROPPED - i));
      end else begin
        truncs[i] = (din_b << (i - BITS_DROPPED));
      end
      
      sum = sum + (din_a[i] ? truncs[i] : 0);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      dout <= 0;
      dout_valid <= 0;
    end else begin
      dout <= sum;
      dout_valid <= din_valid;
    end
  end
    
endmodule
`default_nettype wire