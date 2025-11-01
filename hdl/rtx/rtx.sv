`default_nettype none

module rtx #(
  parameter WIDTH = 320,
  parameter HEIGHT = 180
) (
  input wire clk,
  input wire rst,

  output color8 pixel_color,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done
);
  
endmodule

`default_nettype wire
