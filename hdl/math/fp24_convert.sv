// Convert integers to FP24 and vice versa
// Turn 32-bit integer into FP24

`default_nettype none

// TODO: add offset parameter to allow making fractions
// (basically interprets n as fixed-width fraction)
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

// Offset by FRAC bits
module convert_fp24_uint #(
  parameter integer WIDTH = 8,
  parameter integer FRAC = 8
) (
  input wire clk,
  input wire rst,
  input fp24 x,
  output logic [WIDTH-1:0] n
);
  // Convert |x| to a WIDTH-bit unsigned integer
  logic [6:0] shift_amt;

  always_ff @(posedge clk) begin
    if (x.exp + FRAC < 63) begin
      // Magnitude is <1, round down to 0
      n <= 'h0;

    end else if (x.exp + FRAC > (WIDTH-1) + 63) begin
      // Magnitude is too large to fit in this integer, cooked
      n <= 'hFF;
      
    end else begin
      // Shift mantissa by exponent
      // shift_amt should be between 0 and 7, inclusive
      shift_amt = x.exp + FRAC - 63;
      n <= {1'b1, x.mant} >> (16 - shift_amt);
    end
  end
endmodule

`default_nettype wire
