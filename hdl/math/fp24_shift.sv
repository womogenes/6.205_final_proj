`default_nettype none

module fp24_shift #(
  parameter logic [6:0] SHIFT_AMT = 0
) (
  input fp24 a,
  output fp24 quot
);
  // Divide a given fp24 value by a FIXED power of two by subtracting from exponent
  // quot for quotient
  // Useful for dividing by 2 etc
  // Beware overflow?

  logic [6:0] exp_new;
  assign exp_new = a.exp - SHIFT_AMT;
  assign quot = {a.sign, exp_new, a.mant};
endmodule

`default_nettype wire
