`default_nettype wire

/*
  fp24_sqrt:
    find square root of an fp24 by doing x / sqrt(x)

  timing:
    INV_SQRT_DELAY + 1 (fp24_mul delay)
*/
parameter integer INV_NR_STAGES = 2;
parameter integer INV_STAGE_DELAY = 4;
parameter integer INV_DELAY = INV_NR_STAGES * INV_STAGE_DELAY;

module fp24_sqrt (
  input wire clk,
  input wire rst,

  input fp24 x,
  output fp24 x_inv
);
  // TODO: square root logic
endmodule

`default_nettype none
