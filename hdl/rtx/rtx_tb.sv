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
  input wire [$clog2(MAX_SCENE_BUF_DEPTH)-1:0] num_objs,

  output logic [15:0] rtx_pixel,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done          // i.e. pixel_color valid
);
  object obj;

  // Initialize scene buffer
  // Bind inputs to ray tracer
  scene_buffer #(.INIT_FILE("scene_buffer.mem")) scene_buf (
    .clk(clk),
    .rst(rst),
    .num_objs(num_objs),
    .obj(obj)
  );

  rtx #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) my_rtx (
    .clk(clk),
    .rst(rst),
    .cam(cam),

    .rtx_pixel(rtx_pixel),
    .pixel_h(pixel_h),
    .pixel_v(pixel_v),
    .ray_done(ray_done),

    // Scene buffer wires
    .num_objs(num_objs),
    .obj(obj)
  );

endmodule

`default_nettype wire
