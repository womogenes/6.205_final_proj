`default_nettype none

// Empirically, 16
parameter integer QR_SOLVER_DELAY = 3 + SQRT_DELAY + 2;

module quadratic_solver (
  input wire clk,
  input wire rst,

  input fp b,
  input fp c,

  output fp x0,
  output logic valid
);
  fp b_sq;            // b*b            1 cycle
  fp four_c;          // 4*c            1 cycle
  fp discr;           // b*b - 4*c      3 cycles
  fp sqrt_discr;      // sqrt(discr)    14 cycles
  fp b_piped;         // b              14 cycles
  fp neg_b_piped;     // -b             14 cycles
  fp numer;           // -b - discr     16 cycles

  // result is 1 cycle behind
  fp_mul mul_b_sq(.clk(clk), .a(b), .b(b), .prod(b_sq));
  fp_shift #(.SHIFT_AMT(2)) shift_four_c (.a(c));  // combinational!
  always_ff @(posedge clk) four_c <= shift_four_c.shifted;

  // result is 3 cycles behind
  fp_add add_discr(.clk(clk), .a(b_sq), .b(four_c), .is_sub(1'b1), .sum(discr));

  // result is 14 cycles behind (3 + SQRT_DELAY)
  fp_sqrt sqrt_sqrt_discr(.clk(clk), .x(discr), .sqrt(sqrt_discr));
  pipeline #(.WIDTH(FP_BITS), .DEPTH(SQRT_DELAY+3)) b_pipe (.clk(clk), .in(b), .out(b_piped));

  // result is 16 cycles behind (3 + SQRT_DELAY + 2)
  assign neg_b_piped = {~b_piped[FP_BITS-1], b_piped[FP_BITS-2:0]};
  fp_add add_numer(.clk(clk), .a(neg_b_piped), .b(sqrt_discr), .is_sub(1'b1), .sum(numer));
  fp_shift #(.SHIFT_AMT(-1)) shift_x0 (.a(numer), .shifted(x0));

  // pipeline for valid signal (discr >= 0)
  pipeline #(.WIDTH(1), .DEPTH(SQRT_DELAY+2)) valid_pipe (
    .clk(clk), .in(~discr[FP_BITS-1]), .out(valid)
  );

endmodule

`default_nettype wire
