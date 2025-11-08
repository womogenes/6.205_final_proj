`default_nettype none

module rtx #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter SCENE_BUFFER_INIT_FILE = ""
) (
  input wire clk,
  input wire rst,

  output logic [15:0] rtx_pixel,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done           // i.e. pixel_color valid
);
  fp24 width_fp24;
  make_fp24 #(11) width_maker (.clk(clk), .n(WIDTH >> 4), .x(width_fp24));

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
    ray_done <= ray_done_buf0;
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

  // Initialize scene buffer
  // Bind inputs to ray tracer
  // TODO: allow reprogramming
  logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] scene_buf_obj_idx;
  object scene_buf_obj;
  scene_buffer #(.INIT_FILE(SCENE_BUFFER_INIT_FILE)) scene_buf (
    .clk(clk),
    .rst(rst),
    .obj_idx(scene_buf_obj_idx),
    .obj(scene_buf_obj)
  );

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
    .ray_done(ray_done_buf0),
    .pixel_color(pixel_color),
    .pixel_h_out(pixel_h),
    .pixel_v_out(pixel_v),

    // Scene buffer interface
    .obj_idx(scene_buf_obj_idx),
    .obj(scene_buf_obj)
  );

  // Convert to 565 representation
  convert_fp24_uint #(.WIDTH(5), .FRAC(4)) r_convert (.clk(clk), .x(pixel_color.x), .n(rtx_pixel[4:0]));
  convert_fp24_uint #(.WIDTH(6), .FRAC(5)) g_convert (.clk(clk), .x(pixel_color.y), .n(rtx_pixel[10:5]));
  convert_fp24_uint #(.WIDTH(5), .FRAC(5)) b_convert (.clk(clk), .x(pixel_color.z), .n(rtx_pixel[15:11]));

endmodule

`default_nettype wire
