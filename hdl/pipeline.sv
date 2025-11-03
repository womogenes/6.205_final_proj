`default_nettype none

// We LOVE pipelining

module pipeline #(
  parameter WIDTH, DEPTH
) (
  input wire clk,
  input wire [WIDTH-1:0] in,
  output logic [WIDTH-1:0] out,
  output logic [DEPTH-1:0][WIDTH-1:0] pipe
);
  assign out = pipe[DEPTH-1];

  // Pipe things downnn
  always_ff @(posedge clk) begin
    pipe[0] <= in;
    for (integer i = 1; i < DEPTH; i = i + 1) begin
      pipe[i] <= pipe[i - 1];
    end
  end
endmodule

`default_nettype wire
