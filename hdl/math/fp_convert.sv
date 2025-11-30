// Convert integers to fp and vice versa
// Turn 32-bit integer into fp

`default_nettype none

// TODO: add offset parameter to allow making fractions
// (basically interprets n as fixed-width fraction)
module make_fp #(
  parameter integer WIDTH,
  parameter integer FRAC = 0
) (
  input wire clk,
  input wire rst,
  input wire [WIDTH-1:0] n,
  output fp x
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
  logic [FP_EXP_BITS-1:0] exp;
  assign exp = log2_n + FP_EXP_OFFSET + FRAC;

  always_ff @(posedge clk) begin
    logic [FP_MANT_BITS-1:0] mant;

    // Handle zero case separately
    if (n == 0) begin
      x <= 0;
    end else begin
      mant = (log2_n >= FP_MANT_BITS) ?
        (frac >> (log2_n - FP_MANT_BITS)) :
        (frac << (FP_MANT_BITS - log2_n));
      x <= {sign, exp, mant};
    end
  end
endmodule

// Offset by FRAC bits
module convert_fp_uint #(
  parameter integer WIDTH = 8,
  parameter integer FRAC = 8
) (
  input wire clk,
  input wire rst,
  input fp x,
  output logic [WIDTH-1:0] n,

  output logic [6:0] x_exp,
  output logic [31:0] x_exp_plus_frac
);
  // Convert |x| to a WIDTH-bit unsigned integer
  logic [FP_EXP_BITS-1:0] shift_amt;

  assign x_exp = x.exp;
  assign x_exp_plus_frac = x.exp + FRAC;

  always_ff @(posedge clk) begin
    if (x.exp + FRAC < FP_EXP_OFFSET) begin
      // Magnitude is <1, round down to 0
      n <= 'h0;

    end else if (x.exp + FRAC > (WIDTH-1) + FP_EXP_OFFSET) begin
      // Magnitude is too large to fit in this integer, cooked
      n <= {(WIDTH){1'b1}};
      
    end else begin
      // Shift mantissa by exponent
      // shift_amt should be between 0 and 7, inclusive
      shift_amt = x.exp + FRAC - FP_EXP_OFFSET;
      n <= {1'b1, x.mant} >> (FP_MANT_BITS - shift_amt);
    end
  end
endmodule

`default_nettype wire
