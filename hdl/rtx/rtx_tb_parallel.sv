`default_nettype none

// Testbench for rtx
// All this does is wrap rtx but provide scene buffer as well

module rtx_tb #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,
  input camera cam,

  input logic [10:0] pixel_h_in,
  input logic [9:0] pixel_v_in,

  output logic [15:0] rtx_pixel,
  // output logic [10:0] pixel_h_out,
  // output logic [9:0] pixel_v_out,
  output logic ray_done          // i.e. pixel_color valid
);
  logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx;
  object obj;
  logic obj_last;

  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp24_vec3 ray_origin, ray_dir;
  logic ray_valid_caster;

  // Initialize scene buffer
  // Bind inputs to ray tracer
  scene_buffer #(.INIT_FILE("scene_buffer.mem")) scene_buf (
    .clk(clk),
    .rst(rst),
    .obj_idx(obj_idx),
    .obj(obj),
    .obj_last(obj_last)
  );

  ray_maker #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) maker (
    .clk(clk),
    .rst(rst),

    // Inputs
    .cam(cam),
    .pixel_h_in(pixel_h_in),
    .pixel_v_in(pixel_v_in),
    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid_caster),

    // Outputs
    .pixel_h_out(pixel_h_caster),
    .pixel_v_out(pixel_v_caster)
  );

  logic ray_done_tracer;
  fp24_color pixel_color;

  ray_tracer #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) tracer (
    .clk(clk),
    .rst(rst),

    // Input
    .pixel_h_in(pixel_h_caster),
    .pixel_v_in(pixel_v_caster),
    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(1'b1),

    // Doubles as a "pixel valid" signal
    .ray_done(ray_done_tracer),
    .pixel_color(pixel_color),
    // .pixel_h_out(pixel_h),
    // .pixel_v_out(pixel_v),

    // Scene buffer interface
    .obj_idx(obj_idx),
    .obj(obj),
    .obj_last(obj_last)
  );

  // Convert to 565 representation
  // fp24_color pixel_color_clipped;
  // fp24_clip_upper #(.UPPER_BOUND(24'h3f0000)) r_min(.clk(clk), .a(pixel_color.r), .clipped(pixel_color_clipped.r));
  // fp24_clip_upper #(.UPPER_BOUND(24'h3f0000)) g_min(.clk(clk), .a(pixel_color.g), .clipped(pixel_color_clipped.g));
  // fp24_clip_upper #(.UPPER_BOUND(24'h3f0000)) b_min(.clk(clk), .a(pixel_color.b), .clipped(pixel_color_clipped.b));

  convert_fp24_uint #(.WIDTH(5), .FRAC(5)) r_convert (.clk(clk), .x(pixel_color.r), .n(rtx_pixel[4:0]));
  convert_fp24_uint #(.WIDTH(6), .FRAC(6)) g_convert (.clk(clk), .x(pixel_color.g), .n(rtx_pixel[10:5]));
  convert_fp24_uint #(.WIDTH(5), .FRAC(5)) b_convert (.clk(clk), .x(pixel_color.b), .n(rtx_pixel[15:11]));

  // Delay ray_done by 1 cycle for the conversion
  pipeline #(.WIDTH(1), .DEPTH(1)) ray_done_pipe (.clk(clk), .in(ray_done_tracer), .out(ray_done));

endmodule

`default_nettype wire
