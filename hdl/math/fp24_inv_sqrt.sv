// Compute inverse square root
`default_nettype none

/*
  Optimizations:
    - Ignore the `valid` pipe and just trust that this module is fully pipelined
      with 12-cycle delay
*/

/*
  inv_sqrt_stage:
    computes one stage of Newton's method for inverse square roots

  inputs:
    x: the number to be inverse-square-rooted
    y: current guess

  timing:
    4 clock cycles
*/
module fp24_inv_sqrt_stage (
  input wire clk,
  input wire rst,

  input fp24 x,
  input fp24 y,
  input wire valid_in,

  // output fp24 y_sq,       // y * y
  // output fp24 y_sq_by_x,  // x * y * y
  // output fp24 sub,        // (3 - x * y * y)
  // output fp24 frac,       // (3 - x * y * y) / 2

  output fp24 x_out,
  output fp24 y_next,
  output wire valid_out
);
  localparam fp24 three = 24'h408000;

  fp24 y_piped5;

  pipeline #(.WIDTH(24), .DEPTH(6)) x_pipe (.clk(clk), .in(x), .out(x_out));
  pipeline #(.WIDTH(24), .DEPTH(5)) y_pipe (.clk(clk), .in(y), .out(y_piped5));
  pipeline #(.WIDTH(1), .DEPTH(6)) valid_pipe (.clk(clk), .in(valid_in), .out(valid_out));

  fp24 y_sq;              // y * y
  fp24 y_sq_by_x;         // x * y * y
  fp24 sub;               // (3 - x * y * y)
  fp24 frac;              // (3 - x * y * y) / 2
  
  fp24_mul mul_y_sq(.clk(clk), .a(y), .b(y), .prod(y_sq));
  fp24_mul mul_y_sq_by_x(.clk(clk), .a(y_sq), .b(x_pipe.pipe[0]), .prod(y_sq_by_x));
  
  fp24_add add_sub(.clk(clk), .a(three), .b(y_sq_by_x), .is_sub(1'b1), .sum(sub));
  fp24_shift #(.SHIFT_AMT(1)) div2_frac (.a(sub), .quot(frac));
  
  // Final answer
  fp24_mul mul_y_next(.clk(clk), .a(frac), .b(y_piped5), .prod(y_next));

  always_ff @(posedge clk) begin
    // y_sq <= mul_y_sq.prod;
    // y_sq_by_x <= mul_y_sq_by_x.prod;
    // sub <= add_sub.sum;
    // frac <= div2_frac.quot;
    // y_next <= mul_y_next.prod;
  end
endmodule

/*
  inv_sqrt:
    does the whole inverse square root shebang using Newton-Rhapson

  inputs:
    x: the number to be inverse-square-rooted
    x_valid: whether the input is valid

  timing:
    ???
*/
module fp24_inv_sqrt (
  input wire clk,
  input wire rst,

  input fp24 x,
  input wire x_valid,

  output fp24 inv_sqrt,
  output wire inv_sqrt_valid
);
  // localparam fp24 half = {1'b0, 7'b011_1110, 16'b0};
  localparam fp24 MAGIC_NUMBER = 24'h5e7a09;
  localparam integer NR_STAGES = 3;

  // fp24 half_x;
  // fp24_mul half_x_mult(.a(half), .b(x), .prod(half_x));

  fp24 [NR_STAGES:0] x_buffer;
  fp24 [NR_STAGES:0] y_buffer;
  logic [NR_STAGES:0] valid_buffer;

  // First stage assume combinational
  fp24 init_guess;
  assign init_guess = MAGIC_NUMBER - (x >> 1); // what the fuck???
  
  generate
    genvar i;
    for (i = 0; i < NR_STAGES; i = i + 1) begin
      fp24_inv_sqrt_stage inv_sqrt_stage (
        .clk(clk),
        .rst(rst),
        .x((i == 0) ? x : x_buffer[i]),
        .y((i == 0) ? init_guess : y_buffer[i]),
        .valid_in((i == 0) ? x_valid : valid_buffer[i]),

        .x_out(x_buffer[i + 1]),
        .y_next(y_buffer[i + 1]),
        .valid_out(valid_buffer[i + 1])
      );
    end
  endgenerate

  // Outputs are last stage in the pipeline
  assign inv_sqrt = y_buffer[NR_STAGES];
  assign inv_sqrt_valid = valid_buffer[NR_STAGES];
endmodule

`default_nettype wire
