`default_nettype none

module quadratic_solver (
  input wire clk,
  input wire rst,

  input fp24 a,
  input fp24 b,
  input fp24 c,

  output fp24 x0,
  output fp24 x1,
  output logic valid
);
  // TODO: implement quadratic solver

  // Discriminant pipeline
  fp24 b_sq;            // b*b            1 cycle
  fp24 a_by_c;          // a*c            1 cycle
  fp24 four_a_by_c;     // 4*a*c          1 cycle
  fp24 discr;           // b*b - 4*a*c    3 cycles
  fp24 sqrt_discr;      // sqrt(discr)    14 cycles
  fp24 b_piped;         // b              14 cycles
  fp24 neg_b_piped;     // -b             14 cycles
  fp24 inv_a;           // 1/a            8 cycles
  fp24 inv_a_piped;     // 1/(2a)         16 cycles
  fp24 inv_2a;          // 1/(2a)         16 cycles

  fp24 numer_add;       // b + discr      16 cycles
  fp24 numer_sub;       // b - discr      16 cycles

  // Result
  fp24 x0_pre, x1_pre;

  // result is 1 cycle behind
  fp24_mul mul_b_sq(.clk(clk), .a(b), .b(b), .prod(b_sq));
  fp24_mul mul_a_by_c(.clk(clk), .a(a), .b(c), .prod(a_by_c));
  fp24_shift #(2) shift_four_a_by_c (.a(a_by_c), .shifted(four_a_by_c));  // combinational!

  // result is 3 cycles behind
  fp24_add add_discr(.clk(clk), .a(b_sq), .b(four_a_by_c), .is_sub(1'b1), .sum(discr));

  // result is 14 cycles behind (3 + SQRT_DELAY)
  fp24_sqrt sqrt_sqrt_discr(.clk(clk), .x(discr), .sqrt(sqrt_discr));
  pipeline #(.WIDTH(24), .DEPTH(SQRT_DELAY+3)) b_pipe (.clk(clk), .in(b), .out(b_piped));

  // result is 16 cycles behind (3 + SQRT_DELAY + 2)
  assign neg_b_piped = {~b_piped[23], b_piped[22:0]};
  fp24_add add_numer_add(.clk(clk), .a(neg_b_piped), .b(sqrt_discr), .is_sub(1'b0), .sum(numer_add));
  fp24_add add_numer_sub(.clk(clk), .a(neg_b_piped), .b(sqrt_discr), .is_sub(1'b1), .sum(numer_sub));

  // result is INV_DELAY (10) cycles behind
  fp24_inv inv_inv_a(.clk(clk), .x(a), .inv(inv_a));
  pipeline #(.WIDTH(24), .DEPTH(3+SQRT_DELAY+2-INV_DELAY)) inv_a_pipe (.clk(clk), .in(inv_a), .out(inv_a_piped));
  fp24_shift #(-1) shift_inv_2a (.a(inv_a_piped), .shifted(inv_2a));

  // multiply numerator by 1/(2a)
  // result is INV_DELAY + 1 cycle behind
  fp24_mul mul_x0(.clk(clk), .a(numer_add), .b(inv_2a), .prod(x0_pre));
  fp24_mul mul_x1(.clk(clk), .a(numer_sub), .b(inv_2a), .prod(x1_pre));

  // pipeline for valid signal
  pipeline #(.WIDTH(1), .DEPTH(SQRT_DELAY+4)) valid_pipe (
    .clk(clk), .in(~discr[23]), .out(valid)
  );

  // if a > 0, x0 < x1 (order reversed)
  always_ff @(posedge clk) begin
    x0 <= inv_2a[23] ? x0_pre : x1_pre;
    x1 <= inv_2a[23] ? x1_pre : x0_pre;
  end

endmodule

`default_nettype wire
