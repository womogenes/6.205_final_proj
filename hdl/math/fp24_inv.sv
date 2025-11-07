`default_nettype wire

// Find multiplicative inverse of an fp24
module fp24_inv_stage (
  input wire clk,
  input wire rst,

  input wire x,
  input wire y
  // No valid signals :)

  output fp24 x_out,
  output fp24 y_next
);
  // Iteration step is x * (2 - x * y)
  // https://marc-b-reynolds.github.io/math/2017/09/18/ModInverse.html
  localparam fp24 two = 

endmodule

module fp24_inv (
  input wire clk,
  input wire rst,

  input fp24 x,
  input fp24 x_inv
);

endmodule

`default_nettype none
