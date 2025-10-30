`default_nettype none

module rtx #(
  parameter WIDTH = 320,
  parameter HEIGHT = 180
) (
  input wire clk,
  input wire rst,

  output color8 pixel_color,
  output [10:0] pixel_h,
  output [9:0] pixel_v,
  output logic ray_done
);
  // raytracing logic here
endmodule

`default_nettype wire
