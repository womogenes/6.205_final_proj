`default_nettype none
module counter(
  input wire clk,
  input wire rst,
  input wire [31:0] period,
  output logic [31:0] count
);
  always_ff @(posedge clk) begin
    if (rst || count + 1 >= period) begin
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end
endmodule

`default_nettype wire
