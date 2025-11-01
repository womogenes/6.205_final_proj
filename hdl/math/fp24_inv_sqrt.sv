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
module fp24_inv_sqrt_stage (
  input wire clk,
  input wire rst,
  input fp24 x,
  input fp24 y,

  output fp24 y_next
);
  localparam fp24 three = 24'h408000;
  localparam fp24 half = 24'h3e0000;

  fp24 y_sq;       // y * y
  fp24 y_sq_by_x;  // x * y * y
  fp24 sub;        // (3 - x * y * y)
  fp24 frac;       // (3 - x * y * y) / 2
  
  fp24_mult mult1(.a(y), .b(y), .prod(y_sq));
  fp24_mult mult2(.a(y_sq), .b(x), .prod(y_sq_by_x));
  
  fp24_add add1(.a(three), .b(y_sq_by_x), .is_sub(1'b1), .sum(sub));
  fp24_mult mult3(.a(sub), .b(half), .prod(frac));
  
  // Final answer
  fp24_mult mult4(.a(frac), .b(y), .prod(y_next));
endmodule

module fp24_inv_sqrt (
  input wire clk,
  input wire rst,

  input fp24 x,
  input wire x_valid,

  output fp24 inv_sqrt,
  output wire inv_sqrt_valid
);
  // localparam fp24 half = {1'b0, 7'b011_1110, 16'b0};
  localparam fp24 MAGIC_NUMBER = 24'h5e7a09;


  // fp24 half_x;
  // fp24_mult half_x_mult(.a(half), .b(x), .prod(half_x));

  fp24 [3:0] x_buffer;
  fp24 [3:0] y_buffer;
  fp24 [2:0] y_next_buffer;
  logic [3:0] valid_buffer;
  generate
    genvar i;
    for (i = 0; i < 3; i = i + 1) begin
      fp24_inv_sqrt_stage inv_sqrt_stage (
        .x(x_buffer[i]),
        .y(y_buffer[i]),
        .y_next(y_next_buffer[i])
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_buffer <= 0;
    end else begin
      // move x buffer and valid buffer
      x_buffer[0] <= x;
      valid_buffer[0] <= x_valid;
      for (integer i = 0; i < 3; i = i + 1) begin
        x_buffer[i + 1] <= x_buffer[i];
        valid_buffer[i + 1] <= valid_buffer[i];
        y_buffer[i + 1] <= y_next_buffer[i];
      end

      if (x_valid) begin
        y_buffer[0] <= MAGIC_NUMBER - (x >> 1); // what the fuck???
      end
    end
  end
  assign inv_sqrt = y_buffer[3];
  assign inv_sqrt_valid = valid_buffer[3];
  // 
endmodule
