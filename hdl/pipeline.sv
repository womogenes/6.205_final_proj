`default_nettype none

// We LOVE pipelining

module pipeline #(
  parameter WIDTH, DEPTH
) (
  input wire clk,
  input wire [WIDTH-1:0] in,
  output logic [WIDTH-1:0] out
);
  logic [WIDTH-1:0] pipe [DEPTH-1:0];

  assign out = pipe[0];

  // Pipe things downnn
  always_ff @(posedge clk) begin
    pipe[DEPTH-1] <= in;
    for (integer i = 0; i < DEPTH - 1; i = i + 1) begin
      pipe[i] <= pipe[i + 1];
    end
  end
endmodule

`default_nettype wire
