`default_nettype none

module rtx #(
  parameter WIDTH = 320,
  parameter HEIGHT = 180
) (
  input wire clk,
  input wire rst,

  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done           // i.e. pixel_color valid
);
  camera cam = 0;

  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp24_vec3 ray_origin, ray_dir;
  logic ray_valid_caster;

  ray_caster #(
    .WIDTH(WIDTH), .HEIGHT(HEIGHT)
  ) caster (
    .clk(clk),
    .rst(rst),
    .cam(cam),
    .new_ray(1'b1),

    .pixel_h(pixel_h_caster),
    .pixel_v(pixel_v_caster),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid_caster)
  );

  logic tracer_ready;
  assign ray_done = tracer_ready;

  ray_tracer #(
    .WIDTH(WIDTH), .HEIGHT(HEIGHT)
  ) tracer (
    .clk(clk),
    .rst(rst),

    .pixel_h_in(pixel_h_caster),
    .pixel_v_in(pixel_v_caster),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid_caster),

    .tracer_ready(tracer_ready),
    .pixel_color(pixel_color),
    .pixel_h_out(pixel_h),
    .pixel_v_out(pixel_v)
  );
endmodule

`default_nettype wire
