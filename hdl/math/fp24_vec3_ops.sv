// Vector operations (fp24 vec3 add and multiply)

module fp24_vec3_add (
  input wire clk,
  input wire rst,   // haha are we even gonna use this

  input fp24_vec3 a,
  input fp24_vec3 b,
  input wire is_sub,

  output fp24_vec3 sum
);
  fp24_add add_x(.clk(clk), .rst(rst), .a(a.x), .b(b.x), .is_sub(is_sub), .sum(sum.x));
  fp24_add add_y(.clk(clk), .rst(rst), .a(a.y), .b(b.y), .is_sub(is_sub), .sum(sum.y));
  fp24_add add_z(.clk(clk), .rst(rst), .a(a.z), .b(b.z), .is_sub(is_sub), .sum(sum.z));
endmodule
