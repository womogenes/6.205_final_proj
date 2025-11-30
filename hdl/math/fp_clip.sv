// Take the min of a given fp and some constant

module fp_clip_upper #(
  parameter fp UPPER_BOUND
) (
  input wire clk,
  input wire rst,

  input fp a,
  output fp clipped
);
  always_ff @(posedge clk) begin
    clipped <= fp_greater(a, UPPER_BOUND) ? UPPER_BOUND : a;
  end
endmodule
