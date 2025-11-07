`default_nettype wire

/*
  fp24_inv_stage:
    iteratively improve guess for 1/x, using y as starting guess

  timing:
    3 cycle delay
*/
module fp24_inv_stage (
  input wire clk,
  input wire rst,

  input fp24 x,
  input fp24 y,
  // No valid signals :)

  output fp24 x_out,
  output fp24 y_next
);
  // Iteration step is y * (2 - x * y)
  // https://marc-b-reynolds.github.io/math/2017/09/18/ModInverse.html
  localparam fp24 two = 24'h400000;

  fp24 y_piped3;

  pipeline #(.WIDTH(24), .DEPTH(4)) x_pipe (.clk(clk), .in(x), .out(x_out));
  pipeline #(.WIDTH(24), .DEPTH(3)) y_pipe (.clk(clk), .in(y), .out(y_piped3));

  fp24 x_by_y;
  fp24 two_minus_xby;

  fp24_mul mul_x_by_y(.clk(clk), .a(x), .b(y), .prod(x_by_y));
  fp24_add add_two_minus_xby(.clk(clk), .a(two), .b(x_by_y), .is_sub(1'b1), .sum(two_minus_xby));
  fp24_mul mul_y_next(.clk(clk), .a(y_piped3), .b(two_minus_xby), .prod(y_next));

endmodule

/*
  fp24_inv:
    find multiplicative inverse of an fp24

  timing:
    INV_DELAY (INV_NR_STAGES * INV_STAGE_DELAY)
*/
parameter integer INV_NR_STAGES = 3;
parameter integer INV_STAGE_DELAY = 4;
parameter integer INV_DELAY = INV_NR_STAGES * INV_STAGE_DELAY;

module fp24_inv (
  input wire clk,
  input wire rst,

  input fp24 x,
  output fp24 x_inv
);
  logic [15:0] MAGIC_CONST = 16'hffff;
  localparam NR_STAGES = INV_NR_STAGES;

  fp24 [NR_STAGES:0] x_buffer;
  fp24 [NR_STAGES:0] y_buffer;

  // To construct initial guess: negate exponent, flip all mantissa bits
  fp24 init_guess;
  assign init_guess = { x.sign, 7'd125 - x.exp, MAGIC_CONST ^ x.mant };

  generate
    genvar i;
    for (i = 0; i < NR_STAGES; i = i + 1) begin
      fp24_inv_stage inv_stage (
        .clk(clk),
        .rst(rst),
        .x((i == 0) ? x : x_buffer[i]),
        .y((i == 0) ? init_guess : y_buffer[i]),

        .x_out(x_buffer[i + 1]),
        .y_next(y_buffer[i + 1])
      );
    end
  endgenerate

  // Outputs are last stage in the pipeline
  assign x_inv = y_buffer[NR_STAGES];

endmodule

`default_nettype none
