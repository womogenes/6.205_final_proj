`default_nettype none

// Testbench for rtx
// All this does is wrap rtx but provide scene buffer as well

module rtx_tb #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input wire clk,
  input wire rst,

  output logic [15:0] rtx_pixel,
  output logic [10:0] pixel_h,
  output logic [9:0] pixel_v,
  output logic ray_done          // i.e. pixel_color valid
);
  logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx;
  object obj;
  logic obj_last;

  // Initialize scene buffer
  // Bind inputs to ray tracer
  scene_buffer #(.INIT_FILE("scene_buffer.mem")) scene_buf (
    .clk(clk),
    .rst(rst),
    .obj_idx(obj_idx),
    
    .obj(obj),
    .obj_last(obj_last)
  );

  rtx #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) my_rtx (
    .clk(clk),
    .rst(rst),

    .rtx_pixel(rtx_pixel),
    .pixel_h(pixel_h),
    .pixel_v(pixel_v),
    .ray_done(ray_done),

    // Scene buffer wires
    .obj_idx(obj_idx),
    .obj(obj),
    .obj_last(obj_last)
  );

endmodule

`default_nettype wire
