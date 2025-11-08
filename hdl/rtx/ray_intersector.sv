`default_nettype none

module ray_intersector (
  input wire clk,
  input wire rst,
  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,
  input wire ray_valid,         // single-cycle trigger

  // Running values
  output material hit_mat,
  output fp24_vec3 hit_pos,
  output fp24_vec3 hit_normal,
  output fp24 hit_dist_sq,
  output logic hit_any,
  output logic hit_valid,

  // Scene buffer interface
  output logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx,
  input object obj,
  input wire obj_last
);
  logic busy;
  logic obj_idx_valid;
  logic obj_valid;

  pipeline #(.WIDTH(1), .DEPTH(2)) obj_valid_pipe (.clk(clk), .in(obj_idx_valid), .out(obj_valid));

  always_ff @(posedge clk) begin
    if (rst) begin
      obj_idx <= 0;
      obj_idx_valid <= 1'b0;
      hit_valid <= 1'b0;
      hit_pos <= 0;
      hit_any <= 1'b0;
      hit_dist_sq <= 1'b0;
      busy <= 1'b0;

    end else if (ray_valid && ~busy) begin
      obj_idx <= 0;
      obj_idx_valid <= 1'b1;
      hit_valid <= 1'b0;
      hit_pos <= 0;
      hit_any <= 1'b0;
      hit_dist_sq <= 1'b0;
      busy <= 1'b1;

    end else begin
      // Keep at last index if we're already there, else increment
      if (obj_idx == SCENE_BUFFER_DEPTH - 1) begin
        obj_idx_valid <= 1'b0;
      end else if (busy) begin
        obj_idx <= obj_idx + 1;
      end

      if (sphere_intx_valid) begin
        // Latch in new value if closer than current OR nothing has been hit yet
        if (sphere_intx_hit && (~hit_any || fp24_greater(hit_dist_sq, sphere_intx_hit_dist_sq))) begin
          hit_mat <= sphere_intx_mat;
          hit_pos <= sphere_intx_hit_pos;
          hit_normal <= sphere_intx_hit_norm;
          hit_dist_sq <= sphere_intx_hit_dist_sq;
          hit_any <= 1'b1;
        end

        if (sphere_intx_obj_last) begin
          hit_valid <= 1'b1;
          busy <= 1'b0;
        end
      end

      if (hit_valid) begin
        hit_valid <= 1'b0;
      end
    end
  end

  /*
  We want pipelines for:
    - object last
    - object valid
    - object material
  */
  logic sphere_intx_hit;
  fp24_vec3 sphere_intx_hit_pos;
  fp24 sphere_intx_hit_dist_sq;
  fp24_vec3 sphere_intx_hit_norm;
  logic sphere_intx_valid;
  logic sphere_intx_obj_last;

  // Pipelined hit material (for reflection)
  material sphere_intx_mat;

  // Lowkey don't know why SPHERE_INTX_DELAY is sufficient... would've expected +2
  //    because of the BRAM delay but alas
  pipeline #(.WIDTH(264), .DEPTH(SPHERE_INTX_DELAY)) mat_pipe (.clk(clk), .in(obj.mat), .out(sphere_intx_mat));

  // The actual intersector logic
  sphere_intersector sphere_intx(
    .clk(clk),
    .rst(rst),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .sphere_center(obj.sphere_center),
    .sphere_rad_sq(obj.sphere_rad_sq),
    .sphere_rad_inv(obj.sphere_rad_inv),
    .sphere_valid(obj_valid),
    .obj_last_in(obj_last),

    .hit(sphere_intx_hit),
    .hit_pos(sphere_intx_hit_pos),
    .hit_dist_sq(sphere_intx_hit_dist_sq),
    .hit_norm(sphere_intx_hit_norm),
    .hit_valid(sphere_intx_valid),
    .obj_last_out(sphere_intx_obj_last)
  );

endmodule

`default_nettype wire
