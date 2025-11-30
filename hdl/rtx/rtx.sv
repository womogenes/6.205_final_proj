`default_nettype none

module rtx #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,
  input camera cam,

  output logic [15:0] rtx_pixel,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done,          // i.e. pixel_color valid

  // Dynamic parameter: # of bounces
  input wire [7:0] max_bounces,

  // scene buffer interface
  input wire [$clog2(MAX_NUM_OBJS)-1:0] num_objs,
  input object obj
);
  logic [10:0] pixel_h_caster;
  logic [9:0] pixel_v_caster;

  fp_vec3 ray_origin, ray_dir;
  logic ray_valid_caster;

  // Differential to act as trigger
  logic rst_prev;
  always_ff @(posedge clk) begin
    rst_prev <= rst;
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
  fp_color pixel_color;

  logic tracer_ray_done;

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
    .ray_done(tracer_ray_done),
    .pixel_color(pixel_color),
    .pixel_h_out(pixel_h),
    .pixel_v_out(pixel_v),
    
    // Dynamic parameter: # of bounces
    .max_bounces(max_bounces),

    // Scene buffer interface
    .num_objs(num_objs),
    .obj(obj),

    // SET SEED FOR LFSR HERE
    .lfsr_seed(48'h1)
  );

  // Convert to 565 representation
  // fp_color pixel_color_clipped;
  // fp_clip_upper #(.UPPER_BOUND('h3f0000)) r_min(.clk(clk), .a(pixel_color.r), .clipped(pixel_color_clipped.r));
  // fp_clip_upper #(.UPPER_BOUND('h3f0000)) g_min(.clk(clk), .a(pixel_color.g), .clipped(pixel_color_clipped.g));
  // fp_clip_upper #(.UPPER_BOUND('h3f0000)) b_min(.clk(clk), .a(pixel_color.b), .clipped(pixel_color_clipped.b));

  convert_fp_uint #(.WIDTH(5), .FRAC(5)) r_convert (.clk(clk), .x(pixel_color.r), .n(rtx_pixel[4:0]));
  convert_fp_uint #(.WIDTH(6), .FRAC(6)) g_convert (.clk(clk), .x(pixel_color.g), .n(rtx_pixel[10:5]));
  convert_fp_uint #(.WIDTH(5), .FRAC(5)) b_convert (.clk(clk), .x(pixel_color.b), .n(rtx_pixel[15:11]));

  // Delay ray_done by 1 cycle for the conversion
  pipeline #(.WIDTH(1), .DEPTH(1)) ray_done_pipe (.clk(clk), .in(tracer_ray_done), .out(ray_done));

endmodule

`default_nettype wire
