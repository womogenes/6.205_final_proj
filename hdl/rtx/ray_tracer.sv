`default_nettype none

module ray_tracer #(
  parameter integer WIDTH = 1280,
  parameter integer HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  input wire [10:0] pixel_h_in,
  input wire [9:0] pixel_v_in,

  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,
  input wire ray_valid,
  output fp24_vec3 bias,

  output logic ray_done,
  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out,

  // Interface to scene buffer
  output logic [$clog2(SCENE_BUFFER_DEPTH-1):0] obj_idx,
  input object obj,
  input wire obj_last
);
  // // Whole thing takes 2 cycles (for now)
  // pipeline #(.WIDTH(1), .DEPTH(2)) ray_valid_pipe (.clk(clk), .in(ray_valid), .out(ray_done));

  // // Add 2 to each dimension
  // // fp24_vec3 bias;
  // assign bias = {24'h3f0000, 24'h3f0000, 24'h0};
  // fp24_vec3_add add_pixel_color(.clk(clk), .v(ray_dir), .w(bias), .sum(pixel_color));

  // pipeline #(.WIDTH(11), .DEPTH(2)) pixel_h_pipe (.clk(clk), .in(pixel_h_in), .out(pixel_h_out));
  // pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));

  // Reset the intersector on new ray
  // TODO: change this when we have multiple bounces

  // assign pixel_color = ray_intx.hit_any ? 72'h3f00003f00003f0000 : 0;
  assign pixel_color = ray_intx.hit_any ? ray_intx.hit_mat.emit_color : 0;

  ray_intersector ray_intx (
    .clk(clk),
    .rst(rst),
    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .ray_valid(ray_valid),

    // Outputs
    .hit_mat(),
    .hit_pos(),
    .hit_normal(),
    .hit_dist_sq(),
    .hit_any(),
    .hit_valid(ray_done),

    .obj_idx(obj_idx),
    .obj(obj),
    .obj_last(obj_last)
  );

  pipeline #(.WIDTH(11), .DEPTH(2)) pixel_h_pipe (.clk(clk), .in(pixel_h_in), .out(pixel_h_out));
  pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));
endmodule

`default_nettype wire
