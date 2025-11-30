`default_nettype none

module fp_shift #(
  parameter integer SHIFT_AMT = 0
) (
  input fp a,
  output fp shifted
);
  // Divide a given fp value by a FIXED power of two by subtracting from exponent
  // Useful for dividing by 2 etc
  // Beware overflow?

  assign shifted.sign = a.sign;
  assign shifted.exp = a.exp + SHIFT_AMT;
  assign shifted.mant = a.mant;
endmodule

`default_nettype wire
