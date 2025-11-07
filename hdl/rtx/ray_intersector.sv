`default_nettype none

module (
  input wire clk,
  input wire rst,
  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,

  output wire hit_valid,
  output wire hit_any,
  output fp24_vec3 hit_pos,
  output fp24_vec3 hit_normal,
  output material hit_mat,

  // Scene buffer interface
  output wire obj_idx,
  input object obj
);
  logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx;

  always_ff @(posedge clk) begin
    if (rst) begin
      obj_idx <= 0;
      hit_valid <= 1'b0;

    end else begin
      obj_idx <= 0;
      hit_pos <= sphere_center;
      hit_mat <= obj.mat;
    end
  end

endmodule

`default_nettype wire
