`default_nettype none

module rtx #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  output logic [2:0][7:0] rtx_pixel,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done           // i.e. pixel_color valid
);
  fp24 width_fp24;
  make_fp24 #(11) width_maker (.clk(clk), .n(WIDTH >> 2), .x(width_fp24));

  camera cam;
  assign cam.origin = 72'h0;
  assign cam.right = {24'h3f0000, 24'h000000, 24'h000000};    // (1, 0, 0)
  assign cam.forward = {24'h000000, 24'h000000, width_fp24};  // (0, 0, width)
  assign cam.up = {24'h000000, 24'h3f0000, 24'h000000};       // (0, 1, 0)

  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp24_vec3 ray_origin, ray_dir;
  logic ray_valid_caster;

  // Differential to act as trigger
  logic rst_prev;
  logic ray_done_buf0;

  always_ff @(posedge clk) begin
    rst_prev <= rst;

    if (rst) begin
      ray_done_buf0 <= 1'b0;
      ray_done <= 1'b0;
    end else begin
      ray_done_buf0 <= tracer_ready;
      ray_done <= ray_done_buf0;
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
  fp24_vec3 pixel_color;

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

    // Doubles as a "pixel valid" signal
    .tracer_ready(tracer_ready),
    .pixel_color(pixel_color),
    .pixel_h_out(pixel_h),
    .pixel_v_out(pixel_v)
  );

  // Convert to 565 representation
  convert_fp24_uint #(.WIDTH(8)) r_convert (.clk(clk), .x(pixel_color.x), .n(rtx_pixel[0]));
  convert_fp24_uint #(.WIDTH(8)) g_convert (.clk(clk), .x(pixel_color.y), .n(rtx_pixel[1]));
  convert_fp24_uint #(.WIDTH(8)) b_convert (.clk(clk), .x(pixel_color.z), .n(rtx_pixel[2]));

endmodule

`default_nettype wire
