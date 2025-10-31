`default_nettype none
module ray_caster #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720,
  parameter FOCAL_LENGTH = 10,
  parameter DOF = 0
) (
  input wire clk,
  input wire rst,

  input wire new_ray,

  output vec3 ray_origin,
  output vec3s ray_dir,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_valid
);


endmodule
`default_nettype wire