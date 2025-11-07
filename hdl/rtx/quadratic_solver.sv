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
  fp24 b_sq;        // b*b          1 cycle
  fp24 a_by_c;      // a*c          1 cycle
  fp24 four_a_by_c; // 4*a*c        1 cycle
  fp24 discr;       // b*b - 4*a*c  3 cycles

  // result is 1 cycle behind
  fp24_mul mul_b_sq(.clk(clk), .a(b), .b(b), .prod(b_sq));
  fp24_mul mul_a_by_c(.clk(clk), .a(a), .b(c), .prod(a_by_c));
  fp24_shift #(2) shift_four_a_by_c (.a(a_by_c), .shifted(four_a_by_c));  // combinational!

  // result is 3 cycles behind
  fp24_add add_discr(.clk(clk), .a(b_sq), .b(four_a_by_c), .is_sub(1'b1), .sum(discr));

  assign x0 = discr;
  assign x1 = discr;

endmodule

`default_nettype wire
