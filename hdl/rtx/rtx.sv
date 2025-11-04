`default_nettype none

module rtx #(
  parameter WIDTH = 320,
  parameter HEIGHT = 180
) (
  input wire clk,
  input wire rst,

  output color8 pixel_color,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done
);
  camera cam = 0;

  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp24_vec3 ray_origin, ray_dir;
  logic ray_valid;

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
    .ray_valid(ray_valid)
  );

  logic tracer_ready;
  logic [10:0] pixel_h_tracer;
  logic [9:0] pixel_v_tracer;

  ray_tracer #(
    .WIDTH(WIDTH), .HEIGHT(HEIGHT)
  ) tracer (
    .clk(clk),
    .rst(rst),

    .pixel_h_in(pixel_h_caster),
    .pixel_v_in(pixel_v_caster),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid),

    .tracer_ready(tracer_ready),
    .pixel_color(pixel_color),
    .pixel_h_out(pixel_h_tracer),
    .pixel_v_out(pixel_v_tracer)
  );
endmodule

`default_nettype wire
