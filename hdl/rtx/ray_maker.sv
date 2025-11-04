`default_nettype none

module ray_maker #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter FOCAL_LENGTH = 10,
  parameter DOF = 0
) (
  input wire clk,
  input wire rst,
  
  input camera cam,
  input logic [10:0] pixel_h,
  input logic [9:0] pixel_v,
  input wire new_ray,

  output fp24_vec3 ray_origin,
  output fp24_vec3 ray_dir,
  output logic ray_valid
);
  // Normalize by centering at zero
  logic signed [10:0] pixel_h_norm;
  logic signed [9:0] pixel_v_norm;

  assign pixel_h_norm = $signed(WIDTH / 2) - $signed(pixel_h);
  assign pixel_v_norm = $signed(HEIGHT / 2) - $signed(pixel_v);

  // Normalized device coordinates
  fp24 u, v;
  make_fp24 #(.WIDTH(11)) u_maker (.clk(clk), .n(pixel_h_norm), .x(u));
  make_fp24 #(.WIDTH(10)) v_maker (.clk(clk), .n(pixel_v_norm), .x(v));

endmodule

`default_nettype wire
