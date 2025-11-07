`default_nettype none

module fp24_shift #(
  parameter integer SHIFT_AMT = 0
) (
  input fp24 a,
  output fp24 shifted
);
  // Divide a given fp24 value by a FIXED power of two by subtracting from exponent
  // Useful for dividing by 2 etc
  // Beware overflow?

  assign shifted.sign = a.sign;
  assign shifted.exp = a.exp + SHIFT_AMT;
  assign shifted.mant = a.mant;
endmodule

`default_nettype wire
