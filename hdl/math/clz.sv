`default_nettype none

module clz #(
  parameter integer WIDTH
) (
  input logic [WIDTH-1:0] x,
  output logic [$clog2(WIDTH)-1:0] count
);
  always_comb begin
    count = WIDTH;
    for (integer i = 0; i < WIDTH; i++) begin
      if (x[i]) begin
        count = WIDTH - 1 - i;
      end
    end
  end
endmodule

`default_nettype wire
