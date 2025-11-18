/*
  Add a vec3 to a vec3

  Timing: 2 cycles
*/

`default_nettype none

module fp24_vec3_add (
  input wire clk,
  input wire rst,
  input fp24_vec3 v,
  input fp24_vec3 w,
  input wire is_sub,

  output fp24_vec3 sum
);
  fp24_add add_x(.clk(clk), .rst(rst), .a(v.x), .b(w.x), .is_sub(is_sub), .sum(sum.x));
  fp24_add add_y(.clk(clk), .rst(rst), .a(v.y), .b(w.y), .is_sub(is_sub), .sum(sum.y));
  fp24_add add_z(.clk(clk), .rst(rst), .a(v.z), .b(w.z), .is_sub(is_sub), .sum(sum.z));
endmodule

/*
  Multiply a vec3 by a vec3

  Timing: 1 cycle
*/
module fp24_vec3_mul (
  input wire clk,
  input wire rst,
  input fp24_vec3 v,
  input fp24_vec3 w,

  output fp24_vec3 prod
);
  fp24_mul mul_x(.clk(clk), .rst(rst), .a(v.x), .b(w.x), .prod(prod.x));
  fp24_mul mul_y(.clk(clk), .rst(rst), .a(v.y), .b(w.y), .prod(prod.y));
  fp24_mul mul_z(.clk(clk), .rst(rst), .a(v.z), .b(w.z), .prod(prod.z));
endmodule

/*
  Multiply a vec3 by a scalar

  Timing: 1 cycle
*/
module fp24_vec3_scale (
  input wire clk,
  input wire rst,
  input fp24_vec3 v,
  input fp24 s,

  output fp24_vec3 scaled
);
  fp24_mul mul_x(.clk(clk), .rst(rst), .a(v.x), .b(s), .prod(scaled.x));
  fp24_mul mul_y(.clk(clk), .rst(rst), .a(v.y), .b(s), .prod(scaled.y));
  fp24_mul mul_z(.clk(clk), .rst(rst), .a(v.z), .b(s), .prod(scaled.z));
endmodule

/*
  Shift each component of a vec3 by some integer amount
  Purely combinational
*/
module fp24_vec3_shift #(
  parameter integer SHIFT_AMT
) (
  input fp24_vec3 v,
  output fp24_vec3 shifted
);
  fp24_shift #(.SHIFT_AMT(SHIFT_AMT)) shift_x (.a(v.x), .shifted(shifted.x));
  fp24_shift #(.SHIFT_AMT(SHIFT_AMT)) shift_y (.a(v.y), .shifted(shifted.y));
  fp24_shift #(.SHIFT_AMT(SHIFT_AMT)) shift_z (.a(v.z), .shifted(shifted.z));
endmodule

/*
  Dot product of two vec3s

  Timing:
    VEC3_DOT_DELAY cycles
    Currently 5 (mul - 1, add - 2, add - 2)
*/
module fp24_vec3_dot (
  input wire clk,
  input wire rst,
  input fp24_vec3 v,
  input fp24_vec3 w,
  output fp24 dot
);
  fp24_vec3 prod;
  fp24 sum_xy, z_piped2;

  fp24_vec3_mul mul(.clk(clk), .v(v), .w(w), .prod(prod));

  // Add the elementwise products
  fp24_add add_xy(.clk(clk), .a(prod.x), .b(prod.y), .is_sub(1'b0), .sum(sum_xy));

  // Store z-value because pipeline timing
  pipeline #(.WIDTH(24), .DEPTH(2)) z_pipe (.clk(clk), .in(prod.z), .out(z_piped2));

  // Final add
  fp24_add add_xyz(.clk(clk), .a(sum_xy), .b(z_piped2), .is_sub(1'b0), .sum(dot));
endmodule

/*
  Normalize a vector to have magnitude 1 using inv_sqrt

  Timing:
    VEC3_DOT_DELAY + INV_SQRT_DELAY + SCALE_DELAY (1)
*/
module fp24_vec3_normalize (
  input wire clk,
  input wire rst,
  input fp24_vec3 v,
  output fp24_vec3 normed
);
  // Find |v * v|, i.e. x^2 + y^2 + z^2
  // VEC3_DOT_DELAY cycles
  fp24 mag_sq;
  fp24_vec3_dot dot_mag_sq(.clk(clk), .v(v), .w(v), .dot(mag_sq));

  // Find 1/mag(a)
  // INV_SQRT_DELAY cycles
  fp24 mag_inv;
  fp24_inv_sqrt inv_sqrt_mag(
    .clk(clk), .rst(rst),
    .x(mag_sq), .x_valid(1'b1),
    .inv_sqrt(mag_inv), .inv_sqrt_valid()
  );

  // Delay a for the scaling portion
  fp24_vec3 v_piped;
  pipeline #(
    .WIDTH(72),
    .DEPTH(VEC3_DOT_DELAY + INV_SQRT_DELAY)
  ) v_pipe (
    .clk(clk), .in(v), .out(v_piped)
  );

  // Scaling portion
  // 1 cycle
  fp24_vec3_scale scale_a_norm(.clk(clk), .v(v_piped), .s(mag_inv), .scaled(normed));
endmodule

/*
  Lerp between two fp24_vec3s. Requires both t and one_sub_t for efficiency.

  Timing:
    3 cycles: scale (1) + add (2)
*/
module fp24_vec3_lerp (
  input wire clk,
  input wire rst,

  input fp24_vec3 v,
  input fp24_vec3 w,
  input fp24 t,
  input fp24 one_sub_t,

  output fp24_vec3 lerped
);
  fp24_vec3 v_scaled, w_scaled;

  // Calculate v * (1-t) and w * t
  fp24_vec3_scale v_scaler(.clk(clk), .rst(rst), .v(v), .s(one_sub_t), .scaled(v_scaled));
  fp24_vec3_scale w_scaler(.clk(clk), .rst(rst), .v(w), .s(t), .scaled(w_scaled));

  // Add them together
  fp24_vec3_add adder(.clk(clk), .rst(rst), .v(v_scaled), .w(w_scaled), .is_sub(0), .sum(lerped));
endmodule

`default_nettype wire
