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
endmodule

`default_nettype wire
