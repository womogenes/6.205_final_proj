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

  output logic ray_done,        // back pressure
  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out
);
  // Whole thing takes 2 cycles (for now)
  pipeline #(.WIDTH(1), .DEPTH(2)) ray_valid_pipe (.clk(clk), .in(ray_valid), .out(ray_done));

  // Add 2 to each dimension
  // fp24_vec3 bias;
  assign bias = {24'h3f0000, 24'h3f0000, 24'h0};
  fp24_vec3_add add_pixel_color(.clk(clk), .v(ray_dir), .w(bias), .sum(pixel_color));

  pipeline #(.WIDTH(11), .DEPTH(2)) pixel_h_pipe (.clk(clk), .in(pixel_h_in), .out(pixel_h_out));
  pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));
endmodule

`default_nettype wire
