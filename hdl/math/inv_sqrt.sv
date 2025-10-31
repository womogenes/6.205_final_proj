// Compute inverse square root

/*
  inv_sqrt_stage:
    computes one stage of Newton's method for inverse square roots

  inputs:
    x: the number to be inverse-square-rooted
    y: current guess

  timing:
    4 cycles of delay
*/
module inv_sqrt_stage (
  input wire clk,
  input wire rst,
  input fixed x,
  input fixed y,

  output fixed y_next
);
  localparam logic signed [FULL_WIDTH-1:0] three = (2'b11 << FRAC_WIDTH);

  fixed y_sq;       // y * y
  fixed y_sq_by_x;  // x * y * y
  fixed frac;       // (3 - x * y * y) / 2

  fixed x_piped1;   // x, delayed by 1 cycle
  fixed y_piped3;   // y, delayed by 3 cycles

  pipeline #(.WIDTH(FULL_WIDTH), .DEPTH(1)) x_pipe (.clk(clk), .in(x), .out(x_piped1));
  pipeline #(.WIDTH(FULL_WIDTH), .DEPTH(3)) y_pipe (.clk(clk), .in(y), .out(y_piped3));
  
  mul_fixed mul1(.clk(clk), .din_a(y), .din_b(y), .dout(y_sq));
  mul_fixed mul2(.clk(clk), .din_a(y_sq), .din_b(x_piped1), .dout(y_sq_by_x));
  
  // Calculate (3-x*y*y)/2
  always_ff @(posedge clk) begin
    frac <= (three - y_sq_by_x) >> 1;
  end

  // Final answer
  mul_fixed mul3(.clk(clk), .rst(rst), .din_a(frac), .din_b(y_piped3), .dout(y_next));
endmodule

module inv_sqrt (
  input wire clk,
  input wire 
);
  // 
endmodule
