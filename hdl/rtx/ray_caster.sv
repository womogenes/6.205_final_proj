`default_nettype none

module ray_caster #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,
  
  input camera cam,
  input wire new_ray,

  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output fp24_vec3 ray_origin,
  output fp24_vec3 ray_dir,
  output logic ray_valid
);
  logic [10:0] pixel_h_rsg;
  logic [9:0] pixel_v_rsg;

  ray_signal_gen #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) rsg (
    .clk(clk),
    .rst(rst),
    .new_ray(new_ray),

    .pixel_h(pixel_h_rsg),
    .pixel_v(pixel_v_rsg)
  );
  
  // Maybe we have to pipeline the new_ray signal that goes into ray_maker?
  //   just by a cycle... maybe
  logic [10:0] pixel_h_maker;
  logic [9:0] pixel_v_maker;
  ray_maker #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) maker (
    .clk(clk),
    .rst(rst),

    .cam(cam),
    .pixel_h_in(pixel_h_rsg),
    .pixel_v_in(pixel_v_rsg),
    .new_ray(new_ray),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid),

    .pixel_h_out(pixel_h),
    .pixel_v_out(pixel_v)
  );
endmodule

`default_nettype wire
