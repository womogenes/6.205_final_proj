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

  // "staging" registers to hold stuff until we want to release it
  // `new_ray` triggers the staging release
  logic maker_new_ray;
  fp24_vec3 staging_ray_origin;
  fp24_vec3 staging_ray_dir;
  logic [10:0] staging_pixel_h;
  logic [9:0] staging_pixel_v;

  always_ff @(posedge clk) begin
    // Upon receiving a new_ray signal, we can immediately release
    if (new_ray) begin
      maker_new_ray <= 1'b1;
      ray_valid <= 1'b1;
      ray_origin <= staging_ray_origin;
      ray_dir <= staging_ray_dir;
      pixel_h <= staging_pixel_h;
      pixel_v <= staging_pixel_v;
      
    end else begin
      maker_new_ray <= 1'b0;
      ray_valid <= 1'b0;
    end
  end

  ray_maker #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT)
  ) maker (
    .clk(clk),
    .rst(rst),

    .cam(cam),
    .pixel_h_in(pixel_h_rsg),
    .pixel_v_in(pixel_v_rsg),
    .new_ray(maker_new_ray),

    .ray_origin(staging_ray_origin),
    .ray_dir(staging_ray_dir),
    // TODO: empty because we assume caster is always faster than tracer
    //   but maybe we shouldn't assume this
    .ray_valid(),

    .pixel_h_out(staging_pixel_h),
    .pixel_v_out(staging_pixel_v)
  );
endmodule

`default_nettype wire
