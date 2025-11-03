`default_nettype none

module fp24_div2 (
  input fp24 a,
  output fp24 quot
);
  // Divide a given fp24 value by 2 by subtracting one from exponent
  // quot for quotient
  // ASSUMES a IS POSITIVE

  logic [6:0] exp_minus_one;
  assign exp_minus_one = a[22:16] - 1;
  assign quot = {1'b0, exp_minus_one, a[15:0]};
endmodule

`default_nettype wire
