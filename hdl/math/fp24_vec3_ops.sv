/*
  Add a vec3 to a vec3

  Timing: 1 cycle
*/
module fp24_vec3_add (
  input wire clk,
  input wire rst,
  input fp24_vec3 a,
  input fp24_vec3 b,
  input wire is_sub,

  output fp24_vec3 sum
);
  fp24_add add_x(.clk(clk), .rst(rst), .a(a.x), .b(b.x), .is_sub(is_sub), .sum(sum.x));
  fp24_add add_y(.clk(clk), .rst(rst), .a(a.y), .b(b.y), .is_sub(is_sub), .sum(sum.y));
  fp24_add add_z(.clk(clk), .rst(rst), .a(a.z), .b(b.z), .is_sub(is_sub), .sum(sum.z));
endmodule

/*
  Multiply a vec3 by a vec3

  Timing: combinational
*/
module fp24_vec3_mul (
  input wire clk,
  input wire rst,
  input fp24_vec3 a,
  input fp24_vec3 b,

  output fp24_vec3 prod
);
  fp24_mul mul_x(.clk(clk), .rst(rst), .a(a.x), .b(b.x), .prod(prod.x));
  fp24_mul mul_y(.clk(clk), .rst(rst), .a(a.y), .b(b.y), .prod(prod.y));
  fp24_mul mul_z(.clk(clk), .rst(rst), .a(a.z), .b(b.z), .prod(prod.z));
endmodule

/*
  Multiply a vec3 by a scalar

  Timing: combinational
*/
module fp24_vec3_scale (
  input wire clk,
  input wire rst,
  input fp24_vec3 a,
  input fp24 s,

  output fp24_vec3 prod
);
  fp24_mul mul_x(.clk(clk), .rst(rst), .a(a.x), .b(s), .prod(prod.x));
  fp24_mul mul_y(.clk(clk), .rst(rst), .a(a.y), .b(s), .prod(prod.y));
  fp24_mul mul_z(.clk(clk), .rst(rst), .a(a.z), .b(s), .prod(prod.z));
endmodule

/*
  Dot product of two vec3s

  Timing:
    5 cycles (mul, add, add)
*/
module fp24_vec3_dot (
  input wire clk,
  input wire rst,
  input fp24_vec3 a,
  input fp24_vec3 b,
  output fp24 dot
);
  fp24_vec3 prod;
  fp24 sum_xy, z_piped2;

  fp24_vec3_mul mul(.clk(clk), .a(a), .b(b), .prod(prod));

  // Add the elementwise products
  fp24_add add_xy(.clk(clk), .a(prod.x), .b(prod.y), .sum(sum_xy));

  // Store z-value because pipeline timing
  pipeline #(.WIDTH(24), .DEPTH(2)) z_pipe (.clk(clk), .in(prod.z), .out(z_piped2));

  // Final add
  fp24_add add_xyz(.clk(clk), .a(sum_xy), .b(z_piped2), .sum(dot));
endmodule
