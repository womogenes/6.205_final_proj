`default_nettype none

module ray_intersector (
  input wire clk,
  input wire rst,
  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,

  // Running values
  output material hit_mat,
  output fp24_vec3 hit_pos,
  output fp24_vec3 hit_normal,
  output fp24 hit_dist_sq,
  output logic hit_any,
  output logic hit_valid,

  // Scene buffer interface
  output logic [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx,
  input object obj
);
  logic obj_idx_valid;
  logic obj_valid;

  always_ff @(posedge clk) begin
    if (rst) begin
      obj_idx <= 0;
      obj_idx_valid <= 1'b0;
      hit_any <= 1'b0;
      hit_dist_sq <= 1'b0;

    end else begin
      // Next object
      obj_idx <= (obj_idx >= SCENE_BUFFER_DEPTH - 1) ? 0 : obj_idx + 1;
      obj_idx_valid <= 1'b1;

      if (intx_valid) begin
        // Latch in new value if closer than current OR nothing has been hit yet OR we're at the first object
        // TODO: confirm that this thing runs continuously, i.e. hit_valid is a signal for the next object
        //    having index 0
        if (intx_hit && (~hit_any || fp24_greater(hit_dist_sq, intx_hit_dist_sq || hit_valid))) begin
          hit_mat <= intx_mat;
          hit_pos <= intx_hit_pos;
          hit_normal <= intx_hit_norm;
          hit_dist_sq <= intx_hit_dist_sq;
          hit_any <= 1'b1;
        end
      end
    end
  end

  /*
  We want pipelines for:
    - object last
    - object valid
    - object material
  */
  logic intx_hit;
  fp24_vec3 intx_hit_pos;
  fp24 intx_hit_dist_sq;
  fp24_vec3 intx_hit_norm;
  logic intx_valid;

  // Pipelined hit material (for reflection)
  material intx_mat;

  pipeline #(.WIDTH(1), .DEPTH(2 + SPHERE_INTX_DELAY)) obj_last_pipe (
    .clk(clk),
    .in(obj_idx == SCENE_BUFFER_DEPTH - 1),
    .out(hit_valid)
  );
  pipeline #(.WIDTH(1), .DEPTH(2)) obj_valid_pipe (.clk(clk), .in(obj_idx_valid), .out(obj_valid));
  pipeline #(.WIDTH(264), .DEPTH(SPHERE_INTX_DELAY)) mat_pipe (.clk(clk), .in(obj.mat), .out(intx_mat));

  // The actual intersector logic
  sphere_intersector sphere_intx(
    .clk(clk),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .sphere_center(obj.sphere_center),
    .sphere_rad_sq(obj.sphere_rad_sq),
    .sphere_rad_inv(obj.sphere_rad_inv),
    .sphere_valid(obj_valid),

    .hit(intx_hit),
    .hit_pos(intx_hit_pos),
    .hit_dist_sq(intx_hit_dist_sq),
    .hit_norm(intx_hit_norm),
    .hit_valid(intx_valid)
  );

endmodule

`default_nettype wire
