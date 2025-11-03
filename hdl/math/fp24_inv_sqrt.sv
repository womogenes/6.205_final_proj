// Compute inverse square root
`default_nettype none

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
  
  fp24_mult mul_y_sq(.a(y), .b(y));
  fp24_mult mul_y_sq_by_x(.a(y_sq), .b(x));
  
  // fp24_add add1(.a(three), .b(y_sq_by_x), .is_sub(1'b1), .sum(sub));
  assign sub = fp24_add(three, y_sq_by_x, 1'b1);
  fp24_mult mult3(.a(sub), .b(half), .prod(frac));
  
  // Final answer
  fp24_mult mult4(.a(frac), .b(y), .prod(y_next));
endmodule

/*
  inv_sqrt:
    does the whole inverse square root shebang using Newton-Rhapson

  inputs:
    x: the number to be inverse-square-rooted
    x_valid: whether the input is valid

  timing:
    ???
*/
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
  localparam integer NR_STAGES = 3;

  // fp24 half_x;
  // fp24_mult half_x_mult(.a(half), .b(x), .prod(half_x));

  fp24 [NR_STAGES-1:0] x_buffer;
  fp24 [NR_STAGES-1:0] y_buffer;
  fp24 init_guess;

  fp24 [NR_STAGES-1:0] y_next_buffer;
  logic [NR_STAGES-1:0] valid_buffer;

  // First stage assume combinational
  assign init_guess = MAGIC_NUMBER - (x >> 1); // what the fuck???
  
  generate
    genvar i;
    for (i = 0; i < NR_STAGES; i = i + 1) begin
      fp24_inv_sqrt_stage inv_sqrt_stage (
        .clk(clk),
        .rst(rst),
        .x((i == 0) ? x : x_buffer[i]),
        .y((i == 0) ? init_guess : y_buffer[i]),
        .y_next(y_next_buffer[i])
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_buffer <= 0;
      
    end else begin
      // first stage
      // (could collapse into ternary)
      x_buffer[0] <= x;
      valid_buffer[0] <= x_valid;
      y_buffer[0] <= init_guess;

      // move x buffer and valid buffer
      for (integer i = 1; i < NR_STAGES; i = i + 1) begin
        x_buffer[i] <= x_buffer[i - 1];
        valid_buffer[i] <= valid_buffer[i - 1];
        y_buffer[i] <= y_next_buffer[i - 1];
      end
    end
  end

  // Outputs are last stage in the pipeline
  assign inv_sqrt = y_buffer[NR_STAGES-1];
  assign inv_sqrt_valid = valid_buffer[NR_STAGES-1];
endmodule

`default_nettype wire
