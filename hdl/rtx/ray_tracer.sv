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

  output logic tracer_ready,        // back pressure
  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out
);
  assign tracer_ready = ray_valid;

  // make_fp24 #(.WIDTH(9)) r_maker (.clk(clk), .n(9'd255), .x(pixel_color.r));
  // make_fp24 #(.WIDTH(9)) g_maker (.clk(clk), .n(9'd255), .x(pixel_color.g));
  // make_fp24 #(.WIDTH(9)) b_maker (.clk(clk), .n(9'd255), .x(pixel_color.b));

  // assign pixel_color.x = 'h46fe00;
  // assign pixel_color.y = 'h460000;
  // assign pixel_color.z = 'h450000;

  assign pixel_color = ray_dir;

  assign pixel_h_out = pixel_h_in;
  assign pixel_v_out = pixel_v_in;
endmodule

`default_nettype wire
