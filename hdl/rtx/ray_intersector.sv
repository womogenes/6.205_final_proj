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
  input object obj
);
  // BILL READ THIS SHIT SO I DONT HAVE TO EXPLAIN
  // pre_obj_count keeps track of how many objects went INTO the pipeline (busy)
  // post_obj_count keeps track of how many objects come OUT of the pipeline (valid)

  // since we are looping thru all objects synchronization doesnt matter as long as
  // we check all of them
  logic [$clog2(SCENE_BUFFER_DEPTH + 1)-1:0] pre_obj_count;
  logic [$clog2(SCENE_BUFFER_DEPTH + 1)-1:0] post_obj_count;
  logic busy;
  logic last_obj;

  logic ray_valid_piped;
  pipeline #(
    .WIDTH(1), 
    .DEPTH(SPHERE_INTX_DELAY)
  ) ray_valid_pipe (
    .clk(clk), 
    .in(ray_valid),
    .out(ray_valid_piped));

  assign busy = pre_obj_count < SCENE_BUFFER_DEPTH;
  assign last_obj = post_obj_count == SCENE_BUFFER_DEPTH - 1;

  always_ff @(posedge clk) begin
    if (rst) begin
      hit_valid <= 1'b0;
      hit_pos <= 0;
      hit_any <= 1'b0;
      hit_dist_sq <= 1'b0;
      
      pre_obj_count <= SCENE_BUFFER_DEPTH;
      post_obj_count <= SCENE_BUFFER_DEPTH;

      hit_mat <= 0;
      hit_pos <= 0;
      hit_normal <= 0;
      hit_dist_sq <= 0;
    end else begin
      // count input objects
      if (ray_valid) begin
        pre_obj_count <= 0;
      end else begin
        if (pre_obj_count < SCENE_BUFFER_DEPTH) begin
          pre_obj_count <= pre_obj_count + 1;
        end
      end

      // count processed objects
      if (ray_valid_piped) begin
        post_obj_count <= 0;
      end else begin
        if (post_obj_count < SCENE_BUFFER_DEPTH) begin
          post_obj_count <= post_obj_count + 1;
        end
      end
      
      // first object check of this ray
      if (ray_valid_piped) begin
        if (sphere_intx_hit) begin
          hit_mat <= sphere_intx_mat;
          hit_pos <= sphere_intx_hit_pos;
          hit_normal <= sphere_intx_hit_norm;
          hit_dist_sq <= sphere_intx_hit_dist_sq;
          hit_any <= 1'b1;
        end else begin
          hit_any <= 1'b0;
        end
      end else begin
        if (sphere_intx_hit && 
            (hit_any == 0 || fp24_greater(hit_dist_sq, sphere_intx_hit_dist_sq))) begin
          hit_mat <= sphere_intx_mat;
          hit_pos <= sphere_intx_hit_pos;
          hit_normal <= sphere_intx_hit_norm;
          hit_dist_sq <= sphere_intx_hit_dist_sq;
          hit_any <= 1'b1;
        end
      end
      

      hit_valid <= last_obj;
    end
  end

  /*
  We want pipelines for:
    - ray valid
    - object material
  */
  logic sphere_intx_hit;
  fp24_vec3 sphere_intx_hit_pos;
  fp24 sphere_intx_hit_dist_sq;
  fp24_vec3 sphere_intx_hit_norm;

  // Pipelined hit material (for reflection)
  material sphere_intx_mat;

  pipeline #(
    .WIDTH($bits(material)), 
    .DEPTH(SPHERE_INTX_DELAY)
  ) mat_pipe (
    .clk(clk), 
    .in(obj.mat), 
    .out(sphere_intx_mat));

  // The actual intersector logic
  sphere_intersector sphere_intx(
    .clk(clk),
    .rst(rst),

    .ray_origin(ray_origin),
    .ray_dir(ray_dir),
    .sphere_center(obj.sphere_center),
    .sphere_rad_sq(obj.sphere_rad_sq),
    .sphere_rad_inv(obj.sphere_rad_inv),

    .hit(sphere_intx_hit),
    .hit_pos(sphere_intx_hit_pos),
    .hit_dist_sq(sphere_intx_hit_dist_sq),
    .hit_norm(sphere_intx_hit_norm)
  );

endmodule

`default_nettype wire
