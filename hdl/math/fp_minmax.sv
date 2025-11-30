// Sort two fps

`default_nettype none

module fp_minmax (
  input wire clk,
  input wire rst,
  
  input fp a,
  input fp b,

  output fp min,
  output fp max
);
  logic greater;
  assign greater = fp_greater(a, b);

  always_ff @(posedge clk) begin
    min <= greater ? b : a;
    max <= greater ? a : b;
  end
endmodule

`default_nettype wire
