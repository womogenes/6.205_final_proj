`default_nettype wire

/*
  fp24_sqrt:
    find square root of an fp24 by doing x / sqrt(x)

  timing:
    INV_SQRT_DELAY + fp24_mul delay (1)
*/

module fp24_sqrt (
  input wire clk,
  input wire rst,

  input fp24 x,
  output fp24 sqrt
);
  fp24 x_inv_sqrt;
  fp24 x_piped;
  
  pipeline #(.WIDTH(24), .DEPTH(INV_SQRT_DELAY)) x_pipe (.clk(clk), .in(x), .out(x_piped));

  fp24_inv_sqrt inv_sqrt_x_isq(.clk(clk), .x(x), .inv_sqrt(x_inv_sqrt));
  fp24_mul mul_sqrt(.clk(clk), .a(x_piped), .b(x_inv_sqrt), .prod(sqrt));

endmodule

`default_nettype none
