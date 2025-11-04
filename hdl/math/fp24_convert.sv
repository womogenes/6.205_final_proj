// Convert integers to FP24 and vice versa
// Turn 32-bit integer into FP24

module make_fp24 #(
  parameter integer WIDTH
) (
  input wire clk,
  input wire rst,
  input wire [WIDTH-1:0] n,
  output fp24 x
);
  localparam integer LOG_WIDTH = $clog2(WIDTH);

  // Get sign
  logic sign;
  assign sign = n[WIDTH-1];

  logic [WIDTH-1:0] frac;
  assign frac = ({(WIDTH){sign}} ^ n[WIDTH-1:0]) + sign;
  
  // Logarithm logic to count leading zeros and position of MSB
  logic [LOG_WIDTH-1:0] lead_zeros;
  clz #(.WIDTH(WIDTH)) clz_n (.x(frac), .count(lead_zeros));
  
  logic [LOG_WIDTH-1:0] log2_n;
  assign log2_n = WIDTH - 1 - lead_zeros;

  // Compute exponent as offset MSB position
  logic [6:0] exp;
  assign exp = log2_n + 63;

  always_ff @(posedge clk) begin
    logic [15:0] mant;

    // Handle zero case separately
    if (n == 0) begin
      x <= 0;
    end else begin
      mant = (log2_n >= 16) ? (frac >> (log2_n - 16)) : (frac << (16 - log2_n));
      x <= {sign, exp, mant};
    end
  end
endmodule
