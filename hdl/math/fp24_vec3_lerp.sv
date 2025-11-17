`default_nettype none

module fp24_vec3_lerp (
  input wire clk,
  input wire rst,

  input fp24_vec3 v,
  input fp24_vec3 w,
  input fp24 t,
  input fp24 one_min_t,

  output fp24_vec3 lerped
);
  fp24_vec3 v_scaled, w_scaled;

  // Calculate v * (1-t) and w * t
  fp24_vec3_scale v_scaler(.clk(clk), .rst(rst), .v(v), .s(one_min_t), .scaled(v_scaled));
  fp24_vec3_scale w_scaler(.clk(clk), .rst(rst), .v(w), .s(t), .scaled(w_scaled));

  // Add them together
  fp24_vec3_add adder(.clk(clk), .rst(rst), .v(v_scaled), .w(w_scaled), .is_sub(0), .sum(lerped));
endmodule

`default_nettype wire
