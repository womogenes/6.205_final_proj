`default_nettype none

module ray_tracer (
  input wire clk,
  input wire rst,

  input wire [10:0] pixel_h_in,
  input wire [9:0] pixel_v_in,

  fp24_vec3 ray_origin,
  fp24_vec3 ray_dir,
  input wire ray_valid,

  output logic tracer_ready,
  output fp24_vec3 pixel_color,
  output logic [10:0] pixel_h_out,
  output logic [9:0] pixel_v_out
);
  // Hello
endmodule

`default_nettype wire
