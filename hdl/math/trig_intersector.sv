`default_nettype none

// Compute intersection between ray and triangle

// this number is so cooked we are NOT calculating it parametrically
parameter integer TRIG_INTX_DELAY = 20;

module trig_intersector (
  input wire clk,
  input wire rst,

  input fp_vec3 ray_origin,
  input fp_vec3 ray_dir,
  input fp_vec3 v0,
  input fp_vec3 v0v1,
  input fp_vec3 v0v2,
  input fp_vec3 normal,
  input wire [1:0] obj_type,   // 1: trig, 2: parallelogram, 3: plane

  output logic hit,
  output fp_vec3 hit_pos,
  output fp hit_dist,
  output fp_vec3 hit_norm
);
  fp_vec3 pvec; // available after 3 cycles
  fp_vec3_cross pvec_cross(.clk(clk), .rst(rst), .v(ray_dir), .w(v0v2), .cross_prod(pvec));

  fp_vec3 v0v1_piped; // available after 3 cycles
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(VEC3_CROSS_DELAY)) 
  v0v1_pipe (.clk(clk), .in(v0v1), .out(v0v1_piped));

  fp det; // available after 3 + 5 = 8 cycles
  // if this value is small, the ray is parallel
  fp_vec3_dot det_dot(.clk(clk), .rst(rst), .v(v0v1_piped), .w(pvec), .dot(det));

  //TODO: fact check this number
  fp inv_det; // available after 8 + 8 = 16 cycles it seems?
  fp_inv det_inv (.clk(clk), .rst(rst), .x(det), .inv(inv_det));

  fp_vec3 tvec; // available after 2 cycles
  fp_vec3_add tvec_add (.clk(clk), .rst(rst), .v(ray_origin), .w(v0), .is_sub(1'b1), .sum(tvec));

  fp_vec3 tvec_piped_1; // available after 2 + 1 = 3 cycles
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(1))
  tvec_pipe_1 (.clk(clk), .in(tvec), .out(tvec_piped_1));

  fp u_unnormalized; // available after 3 + 5 = 8 cycles
  fp_vec3_dot u_dot (.clk(clk), .rst(rst), .v(tvec_piped_1), .w(pvec), .dot(u_unnormalized));

  // NOTE: inputs are unnecessarily pipelined idgaf
  fp_vec3 qvec; // available after 3 + 3 = 6 cycles
  fp_vec3_cross qvec_cross (.clk(clk), .rst(rst), .v(tvec_piped_1), .w(v0v1_piped), .cross_prod(qvec));

  fp_vec3 dir_piped_1; // available after 6 cycles
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(6))
  dir_pipe_1 (.clk(clk), .in(ray_dir), .out(dir_piped_1));

  fp v_unnormalized; //available after 6 + 5 = 11 cycles
  fp_vec3_dot v_dot (.clk(clk), .rst(rst), .v(dir_piped_1), .w(qvec), .dot(v_unnormalized));

  fp_vec3 v0v2_piped;
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(6))
  v0v2_pipe (.clk(clk), .in(v0v2), .out(v0v2_piped));

  fp t_unnormalized; // available after 6 + 5 = 11 cycles
  fp_vec3_dot t_dot (.clk(clk), .rst(rst), .v(v0v2_piped), .w(qvec), .dot(t_unnormalized));

  fp u_unnormalized_piped; // available after 11 cycles
  pipeline #(.WIDTH($bits(fp)), .DEPTH(3))
  u_pipe (.clk(clk), .in(u_unnormalized), .out(u_unnormalized_piped));

  logic in_square_u_v; // available after 11 cycles
  assign in_square_u_v = (
    fp_greater(det_pipe.pipe[2], u_unnormalized_piped) &&
    fp_greater(det_pipe.pipe[2], v_unnormalized)
  );

  logic in_square_u_v_piped;  // available after 13 cycles
  pipeline #(.WIDTH($bits(fp)), .DEPTH(2)) in_square_u_v_pipe (
    .clk(clk), .in(in_square_u_v), .out(in_square_u_v_piped)
  );

  fp u_plus_v_unnormalized; // available after 11 + 2 = 13 cycles
  fp_add u_plus_v_add(.clk(clk), .rst(rst), .a(u_unnormalized_piped), .b(v_unnormalized), .is_sub(0), .sum(u_plus_v_unnormalized));

  logic det_sign_piped; // available after 13 cycles
  pipeline #(.WIDTH(1), .DEPTH(3))
  det_sign_pipe (.clk(clk), .in(det.sign), .out(det_sign_piped));
  
  // u and v are both positive
  logic is_pos_u_v; // available after 11 cycles
  assign is_pos_u_v = (
    u_unnormalized_piped.sign == det_sign_piped && 
    v_unnormalized.sign == det_sign_piped);

  fp det_piped; // available after 13 cycles
  pipeline #(.WIDTH($bits(fp)), .DEPTH(5))
  det_pipe (.clk(clk), .in(det), .out(det_piped));
  // u + v < 1 && det > epsilon
  logic in_bounds_u_plus_v; // available after 13 cycles
  localparam fp EPSILON = 24'h2f0000; // some small value to check for small determinant
  assign in_bounds_u_plus_v = (
    ~(fp_greater(u_plus_v_unnormalized, det_piped))
    && fp_greater(det_piped, EPSILON)
  );

  logic is_pos_u_v_piped; // available after 13 cycles
  pipeline #(.WIDTH(1), .DEPTH(2))
  is_pos_u_v_pipe (.clk(clk), .in(is_pos_u_v), .out(is_pos_u_v_piped));
  
  logic [1:0] obj_type_piped; // available after 13 cycles
  pipeline #(.WIDTH(2), .DEPTH(13)) obj_type_pipe (
    .clk(clk), .in(obj_type), .out(obj_type_piped)
  );

  logic in_bounds; // available after 13 cycles
  always_comb begin
    case (obj_type_piped)
      2'b01: in_bounds = in_bounds_u_plus_v && is_pos_u_v_piped;
      2'b10: in_bounds = in_square_u_v_piped && is_pos_u_v_piped;
      2'b11: in_bounds = 1'b1;
      default: in_bounds = 1'b1;
    endcase
  end

  logic in_bounds_piped; // available after 17 cycles
  pipeline #(.WIDTH(1), .DEPTH(4))
  in_bounds_pipe (.clk(clk), .in(in_bounds), .out(in_bounds_piped));

  fp t_piped; // available after 16 cycles
  pipeline #(.WIDTH($bits(fp)), .DEPTH(5))
  t_pipe (.clk(clk), .in(t_unnormalized), .out(t_piped));

  fp t; // available after 17 cycles
  fp_mul t_mul(.clk(clk), .rst(rst), .a(t_piped), .b(inv_det), .prod(t));

  logic t_hit; // available after 17 cycles
  assign t_hit = (t.sign == 1'b0) && fp_greater(t, EPSILON) && in_bounds_piped;

  fp_vec3 dir_piped_2; // available after 17 cycles
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(17))
  dir_pipe_2 (.clk(clk), .in(ray_dir), .out(dir_piped_2));

  fp_vec3 t_scaled; // available after 17 + 1 = 18 cycles
  fp_vec3_scale t_dir_mul(.clk(clk), .rst(rst), .v(dir_piped_2), .s(t), .scaled(t_scaled));

  fp_vec3 origin_piped; // available after 18 cycles
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(18))
  origin_pipe (.clk(clk), .in(ray_origin), .out(origin_piped));

  // hit available after 20 cycles
  pipeline #(.WIDTH(1), .DEPTH(3))
  hit_pipe (.clk(clk), .in(t_hit), .out(hit));

  // hit_pos available after 18 + 2 = 20 cycles
  fp_vec3_add hit_pos_add(.clk(clk), .rst(rst), .v(origin_piped), .w(t_scaled), .is_sub(0), .sum(hit_pos));

  // hit_dist available after 20 cycles
  pipeline #(.WIDTH($bits(fp)), .DEPTH(3))
  hit_dist_pipe (.clk(clk), .in(t), .out(hit_dist));

  // hit_norm available after 20 cycles
  fp_vec3 normal_piped;
  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(8))
  normal_pipe (.clk(clk), .in(normal), .out(normal_piped));

  logic back_face;
  assign back_face = det.sign;
  fp_vec3 hit_norm_flipped;
  assign hit_norm_flipped = {3{back_face, {(FP_BITS - 1){1'b0}}}} ^ normal_piped;

  pipeline #(.WIDTH($bits(fp_vec3)), .DEPTH(12))
  hit_norm_pipe (.clk(clk), .in(hit_norm_flipped), .out(hit_norm));

endmodule

`default_nettype wire
