`default_nettype none

parameter integer QR_SOLVER_DELAY = 3 + SQRT_DELAY + 2;

module quadratic_solver (
  input wire clk,
  input wire rst,

  input fp24 b,
  input fp24 c,

  output fp24 x0,
  output logic valid
);
  fp24 b_sq;            // b*b            1 cycle
  fp24 four_c;          // 4*c            1 cycle
  fp24 discr;           // b*b - 4*c      3 cycles
  fp24 sqrt_discr;      // sqrt(discr)    14 cycles
  fp24 b_piped;         // b              14 cycles
  fp24 neg_b_piped;     // -b             14 cycles
  fp24 numer;           // -b - discr     16 cycles

  // result is 1 cycle behind
  fp24_mul mul_b_sq(.clk(clk), .a(b), .b(b), .prod(b_sq));
  fp24_shift #(.SHIFT_AMT(2)) shift_four_c (.a(c));  // combinational!
  always_ff @(posedge clk) four_c <= shift_four_c.shifted;

  // result is 3 cycles behind
  fp24_add add_discr(.clk(clk), .a(b_sq), .b(four_c), .is_sub(1'b1), .sum(discr));

  // result is 14 cycles behind (3 + SQRT_DELAY)
  fp24_sqrt sqrt_sqrt_discr(.clk(clk), .x(discr), .sqrt(sqrt_discr));
  pipeline #(.WIDTH(24), .DEPTH(SQRT_DELAY+3)) b_pipe (.clk(clk), .in(b), .out(b_piped));

  // result is 16 cycles behind (3 + SQRT_DELAY + 2)
  assign neg_b_piped = {~b_piped[23], b_piped[22:0]};
  fp24_add add_numer(.clk(clk), .a(neg_b_piped), .b(sqrt_discr), .is_sub(1'b1), .sum(numer));
  fp24_shift #(.SHIFT_AMT(-1)) shift_x0 (.a(numer), .shifted(x0));

  // pipeline for valid signal (discr >= 0)
  pipeline #(.WIDTH(1), .DEPTH(SQRT_DELAY+2)) valid_pipe (
    .clk(clk), .in(~discr[23]), .out(valid)
  );

endmodule

`default_nettype wire
