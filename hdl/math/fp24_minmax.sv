// Sort two fp24s

`default_nettype none

module fp24_minmax (
  input wire clk,
  input wire rst,
  
  input fp24 a,
  input fp24 b,

  output fp24 min,
  output fp24 max
);
  logic greater;
  assign greater = fp24_greater(a, b);

  always_ff @(posedge clk) begin
    min <= greater ? b : a;
    max <= greater ? a : b;
  end
endmodule

`default_nettype wire
