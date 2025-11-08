// Take the min of a given fp24 and some constant

module fp24_clip_upper #(
  parameter fp24 UPPER_BOUND
) (
  input wire clk,
  input wire rst,

  input fp24 a,
  output fp24 clipped
);
  always_ff @(posedge clk) begin
    clipped <= fp24_greater(a, UPPER_BOUND) ? UPPER_BOUND : a;
  end
endmodule
