`default_nettype none

module rtx #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done           // i.e. pixel_color valid
);
  fp24 width_fp24;
  make_fp24 #(11) width_maker (.clk(clk), .n(WIDTH), .x(width_fp24));

  camera cam;
  assign cam.origin = 72'b0;
  assign cam.right = {24'h3f0000, 24'h0, 24'h0};    // (1, 0, 0)
  assign cam.forward = {24'h0, 24'h0, width_fp24};  // (0, 0, -500)
  assign cam.up = {24'h0, 24'h3f0000, 24'h0};       // (0, 1, 0)

  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp24_vec3 ray_origin, ray_dir;
  logic ray_valid_caster;

  // Differential to act as trigger
  logic rst_prev;

  always_ff @(posedge clk) begin
    rst_prev <= rst;

    if (rst) begin
      ray_done <= 1'b0;
    end else begin
      ray_done <= tracer_ready;
    end
  end

  ray_caster #(
    .WIDTH(WIDTH), .HEIGHT(HEIGHT)
  ) caster (
    .clk(clk),
    .rst(rst),
    .cam(cam),
    .new_ray((!rst && rst_prev) || ray_done),

    .pixel_h(pixel_h_caster),
    .pixel_v(pixel_v_caster),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid_caster)
  );

  logic tracer_ready;

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
