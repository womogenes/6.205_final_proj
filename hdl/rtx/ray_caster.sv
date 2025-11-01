`default_nettype none

module ray_caster #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720
) (
  input wire clk,
  input wire rst,

  input wire new_ray,

  output vec3 ray_origin,
  output vec3s ray_dir,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_valid
);

  logic [10:0] pixel_h_rsg;
  logic [9:0] pixel_v_rsg;

  assign ray_valid = 1'b1;

  ray_signal_gen #(
    .SIZE_H(SIZE_H),
    .SIZE_V(SIZE_V)
  ) rsg (
    .clk(clk),
    .rst(rst),
    .new_ray(new_ray),
    .pixel_h(pixel_h_rsg),
    .pixel_v(pixel_v_rsg)
  );

  // ray_maker #(
  //   .SIZE_H(SIZE_H),
  //   .SIZE_V(SIZE_V)
  // )
endmodule
`default_nettype wire
