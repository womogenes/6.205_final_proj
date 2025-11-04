`default_nettype none

module ray_maker #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720,
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
  // Turn pixel_h and pixel_v into floats eek

  logic signed [10:0] pixel_h_norm;
  logic signed [9:0] pixel_v_norm;

endmodule

`default_nettype wire
