`default_nettype none

// Compute reflected ray properties after bouncing off of smth

parameter integer RAY_RFLX_DELAY = VEC3_NORM_DELAY + 2;

module ray_reflector (
  input wire clk,
  input wire rst,

  input fp_vec3 ray_dir,
  input fp_color ray_color,
  input fp_color income_light,

  input fp_vec3 hit_pos,
  input fp_vec3 hit_normal,
  input material hit_mat,
  input wire hit_valid,

  output fp_vec3 new_dir,
  output fp_vec3 new_origin,
  output fp_color new_color,
  output fp_color new_income_light,
  output logic reflect_done,

  // DEBUG: to be used only for testbench
  input wire [95:0] lfsr_seed
);
  // Pipelining go brr
  pipeline #(.WIDTH(1), .DEPTH(37)) done_pipe (
    .clk(clk),
    .in(hit_valid),
    .out(reflect_done)
  );

  // ===== BRANCH 0: specular_amt =====
  fp spec_amt;
  logic [7:0] rng_specular;
  prng8 rng8 (
    .clk(clk),
    .rst(rst),
    .seed(lfsr_seed[47:0]),
    .rng(rng_specular)
  );
  logic is_specular;
  assign is_specular = rng_specular < hit_mat.specular_prob;

  always_comb begin
    if (rng_specular < hit_mat.specular_prob) begin
      spec_amt = hit_mat.smoothness;
    end else begin
      spec_amt = 0;
    end
  end

  logic [7:0] hit_mat_specular_prob;
  assign hit_mat_specular_prob = hit_mat.specular_prob;

  // Calculate (1 - specular_amt)
  fp one_sub_spec_amt;
  fp_add sub_spec_amt (
    .clk(clk),
    .a(FP_ONE),
    .b(spec_amt),
    .is_sub(1'b1),
    .sum(one_sub_spec_amt)
  );

  // Pipeline t, 1-t for direction calculation
  fp spec_amt_piped_dir;
  fp one_sub_spec_amt_piped_dir;
  pipeline #(.WIDTH(FP_BITS), .DEPTH(18)) spec_amt_pipe (
    .clk(clk),
    .in(spec_amt),
    .out(spec_amt_piped_dir)
  );
  pipeline #(.WIDTH(FP_BITS), .DEPTH(16)) one_sub_spec_amt_pipe (
    .clk(clk),
    .in(one_sub_spec_amt),
    .out(one_sub_spec_amt_piped_dir)
  );

  // ===== BRANCH 1: RAY DIRECTION =====

  // Diffuse direction
  // 18 cycles behind
  fp_vec3 rng_vec;
  prng_sphere_lfsr prng_sphere (
    .clk(clk),
    .rst(rst),
    .seed(lfsr_seed[95:48]),
    .rng_vec(rng_vec)
  );
  fp_vec3 rng_added;
  fp_vec3_add diffuse_adder (
    .clk(clk),
    .rst(rst),
    .v(rng_vec),
    .w(hit_normal),
    .is_sub(1'b0),
    .sum(rng_added)
  );
  fp_vec3 diffuse_dir;
  fp_vec3_normalize diffuse_normalizer (
    .clk(clk),
    .rst(rst),
    .v(rng_added),
    .normed(diffuse_dir)
  );

  // Specular direction
  fp_vec3 specular_dir;
  specular_reflect spec_reflector (
    .clk(clk),
    .rst(rst),
    .in_dir(ray_dir),
    .normal(hit_normal),
    .out_dir(specular_dir)
  );

  // Delay the specular direction
  // 18 cycles behind
  fp_vec3 specular_dir_piped;
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(10)) spec_dir_pipe (
    .clk(clk),
    .in(specular_dir),
    .out(specular_dir_piped)
  );

  // Lerp from specular dir to diffuse dir
  fp_vec3 new_ray_dir_prenorm;
  fp_vec3_lerp lerp_dir (
    .clk(clk),
    .rst(rst),
    .v(diffuse_dir),
    .w(specular_dir_piped),
    .t(spec_amt_piped_dir),
    .one_sub_t(one_sub_spec_amt_piped_dir),
    .lerped(new_ray_dir_prenorm)
  );

  // Normalize new dir
  fp_vec3_normalize norm_dir (
    .clk(clk),
    .v(new_ray_dir_prenorm),
    .normed(new_dir)
  );

  // Pipeline the origin
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(37)) origin_pipe (
    .clk(clk),
    .in(hit_pos),
    .out(new_origin)
  );

  // ===== BRANCH 2: NEW COLOR =====

  // Calculate additional incoming light
  // 1 cycle behind
  fp_color extra_income_light;
  fp_vec3_mul mul_extra_income_light (
    .clk(clk),
    .v(ray_color),
    .w(hit_mat.emit_color),
    .prod(extra_income_light)
  );

  // Calculate new incoming light
  // 3 cycles behind
  // Requires big pipeline ahead of it to delay accordingly
  fp_color new_income_light_unpiped;
  fp_vec3_add add_new_income_light (
    .clk(clk),
    .rst(rst),
    .v(extra_income_light),
    .w(income_light),
    .is_sub(1'b0),
    .sum(new_income_light_unpiped)
  );
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(34)) new_income_light_pipe (
    .clk(clk),
    .in(new_income_light_unpiped),
    .out(new_income_light)
  );

  // Calculate new ray color
  // Lerp between ray color and specular color
  fp_color true_mat_color;
  fp_color mat_color_piped;
  fp_color mat_spec_color_piped;

  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(2)) mat_color_pipe (
    .clk(clk),
    .in(hit_mat.color),
    .out(mat_color_piped)
  );
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(2)) mat_spec_color_pipe (
    .clk(clk),
    .in(hit_mat.spec_color),
    .out(mat_spec_color_piped)
  );

  fp_vec3_lerp lerp_true_mat_color (
    .clk(clk),
    .rst(rst),
    .v(mat_color_piped),
    .w(mat_spec_color_piped),
    .t(spec_amt_pipe.pipe[1]),
    .one_sub_t(one_sub_spec_amt),
    .lerped(true_mat_color)
  );

  // Combine ray_color and true_mat_color to get new ray color
  fp_color ray_color_piped;
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(5)) ray_color_pipe (
    .clk(clk),
    .in(ray_color),
    .out(ray_color_piped)
  );
  fp_color new_color_unpiped;
  fp_vec3_mul mul_new_ray_color (
    .clk(clk),
    .rst(rst),
    .v(ray_color_piped),
    .w(true_mat_color),
    .prod(new_color_unpiped)
  );
  pipeline #(.WIDTH(FP_VEC3_BITS), .DEPTH(31)) new_ray_color_pipe (
    .clk(clk),
    .in(new_color_unpiped),
    .out(new_color)
  );
  
endmodule

`default_nettype wire
