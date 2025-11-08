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
  logic busy;

  always_ff @(posedge clk) begin
    if (rst) begin
      busy <= 1'b0;

    end else begin
      if (ray_valid) begin
        
      end
    end
  end

  assign pixel_color = ray_intx.hit_any ? ray_intx.hit_normal : 0;

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

  // pipeline #(.WIDTH(11), .DEPTH(2)) pixel_h_pipe (.clk(clk), .in(pixel_h_in), .out(pixel_h_out));
  // pipeline #(.WIDTH(10), .DEPTH(2)) pixel_v_pipe (.clk(clk), .in(pixel_v_in), .out(pixel_v_out));

  // I think we can assume this because inputs should be held constant?
  assign pixel_h_out = pixel_h_in;
  assign pixel_v_out = pixel_v_in;
endmodule

`default_nettype wire
