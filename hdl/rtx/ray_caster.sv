`default_nettype none

module ray_caster #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720
) (
  input wire clk,
  input wire rst,
  
  input camera cam,
  input wire new_ray,

  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output vec3 ray_origin,
  output vec3s ray_dir,
  output logic ray_valid
);

  logic [10:0] pixel_h_rsg;
  logic [9:0] pixel_v_rsg;

  assign ray_valid = 1'b1;

  ray_signal_gen #(
    .SIZE_H(SIZE_H),
    .SIZE_V(SIZE_V)
  ) rsg (
    .clk(clk),
    .rst(rst),
    .new_ray(new_ray),

    .pixel_h(pixel_h_rsg),
    .pixel_v(pixel_v_rsg)
  );
  
  // TODO: maybe we have to pipeline the new_ray signal that goes into ray_maker?
  //   just by a cycle... maybe
  logic [10:0] pixel_h_maker;
  logic [9:0] pixel_v_maker;
  ray_maker #(
    .SIZE_H(SIZE_H),
    .SIZE_V(SIZE_V)
  ) (
    .clk(clk),
    .rst(rst),

    .cam(cam),
    .pixel_h(pixel_h_rsg),
    .pixel_v(pixel_v_rsg),
    .new_ray(new_ray),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid)
  );
endmodule

`default_nettype wire
