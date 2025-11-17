`default_nettype none

// Compute reflected ray properties after bouncing off of smth

parameter integer RAY_RFLX_DELAY = VEC3_NORM_DELAY + 2;

module ray_reflector (
  input wire clk,
  input wire rst,

  input fp24_vec3 ray_dir,
  input fp24_color ray_color,
  input fp24_color income_light,

  input fp24_vec3 hit_pos,
  input fp24_vec3 hit_normal,
  input material hit_mat,
  input wire hit_valid,

  output fp24_vec3 new_dir,
  output fp24_vec3 new_origin,
  output fp24_color new_color,
  output fp24_color new_income_light,
  output logic reflect_done,

  // DEBUG: to be uxed only for testbench
  input logic [47:0] lfsr_seed
);
  // Pipelining go brr

  // ===== BRANCH 0: specular_amt =====
  fp24 spec_amt;
  logic [7:0] rng_specular;
  prng8 rng (
    .clk(clk),
    .rst(rst),
    .seed(lfsr_seed),
    .rng(rng_specular)
  );
  always_comb begin
    if (rng_specular < hit_mat.specular_prob) begin
      spec_amt = hit_mat.smoothness;
    end else begin
      // spec_amt = 0;
    end
  end

  fp24 hit_mat_specular_prob;
  assign hit_mat_specular_prob = hit_mat.specular_prob;

  // Calculate (1 - specular_amt)
  fp24 one_sub_spec_amt;
  fp24_add sub_spec_amt (
    .clk(clk),
    .a(24'h3f0000),
    .b(spec_amt),
    .is_sub(1'b1),
    .sum(one_sub_spec_amt)
  );

  // Pipeline t, 1-t for direction calculation
  fp24 spec_amt_piped_dir;
  fp24 one_sub_spec_amt_piped_dir;
  pipeline #(.WIDTH(24), .DEPTH(18)) spec_amt_pipe (
    .clk(clk),
    .in(spec_amt),
    .out(spec_amt_piped_dir)
  );
  pipeline #(.WIDTH(28), .DEPTH(16)) one_sub_spec_amt_pipe (
    .clk(clk),
    .in(one_sub_spec_amt),
    .out(one_sub_spec_amt_piped_dir)
  );

  // ===== BRANCH 1: RAY DIRECTION =====

  // Diffuse direction
  // 18 cycles behind
  fp24_vec3 rng_vec;
  prng_sphere_lfsr prng_sphere (
    .clk(clk),
    .rst(rst),
    .seed(lfsr_seed),
    .rng_vec(rng_vec)
  );
  fp24_vec3 rng_added;
  fp24_vec3_add diffuse_adder (
    .clk(clk),
    .rst(rst),
    .v(rng_vec),
    .w(hit_normal),
    .is_sub(1'b0),
    .sum(rng_added)
  );
  fp24_vec3 diffuse_dir;
  fp24_vec3_normalize diffuse_normalizer (
    .clk(clk),
    .rst(rst),
    .v(rng_added),
    .normed(diffuse_dir)
  );

  // Specular direction
  fp24_vec3 specular_dir;
  specular_reflect spec_reflector (
    .clk(clk),
    .rst(rst),
    .in_dir(ray_dir),
    .normal(hit_normal),
    .out_dir(specular_dir)
  );

  // Delay the specular direction
  // 18 cycles behind
  fp24_vec3 specular_dir_piped;
  pipeline #(.WIDTH(72), .DEPTH(10)) spec_dir_pipe (
    .clk(clk),
    .in(specular_dir),
    .out(specular_dir_piped)
  );

  // Lerp from specular dir to diffuse dir
  fp24_vec3 new_ray_dir_prenorm;
  fp24_vec3_lerp lerp_dir (
    .clk(clk),
    .rst(rst),
    .v(specular_dir_piped),
    .w(diffuse_dir),
    .t(spec_amt_piped_dir),
    .one_sub_t(one_sub_spec_amt_piped_dir),
    .lerped(new_ray_dir_prenorm)
  );

  // Normalize new dir
  fp24_vec3_normalize norm_dir (
    .clk(clk),
    .v(new_ray_dir_prenorm),
    .normed(new_dir)
  );

  // Pipeline the origin
  pipeline #(.WIDTH(72), .DEPTH(37)) origin_pipe (
    .clk(clk),
    .in(hit_pos),
    .out(new_origin)
  );

  // ===== BRANCH 2: NEW COLOR =====

  // Calculate additional incoming light
  // 1 cycle behind
  fp24_color extra_income_light;
  fp24_vec3_mul mul_extra_income_light (
    .clk(clk),
    .v(ray_color),
    .w(hit_mat.emit_color),
    .prod(extra_income_light)
  );

  // Calculate new incoming light
  // 3 cycles behind
  // Requires big pipeline ahead of it to delay accordingly
  fp24_color new_income_light_unpiped;
  fp24_vec3_add add_new_income_light (
    .clk(clk),
    .rst(rst),
    .v(extra_income_light),
    .w(income_light),
    .is_sub(1'b0),
    .sum(new_income_light_unpiped)
  );
  pipeline #(.WIDTH(72), .DEPTH(34)) new_income_light_pipe (
    .clk(clk),
    .in(new_income_light_unpiped),
    .out(new_income_light)
  );

  // Calculate new ray color
  // Lerp between ray color and specular color
  fp24_color true_mat_color;
  fp24_color mat_color_piped;
  fp24_color mat_spec_color_piped;

  pipeline #(.WIDTH(72), .DEPTH(2)) mat_color_pipe (
    .clk(clk),
    .in(hit_mat.color),
    .out(mat_color_piped)
  );
  pipeline #(.WIDTH(72), .DEPTH(2)) mat_spec_color_pipe (
    .clk(clk),
    .in(hit_mat.spec_color),
    .out(mat_spec_color_piped)
  );

  fp24_vec3_lerp lerp_true_mat_color (
    .clk(clk),
    .rst(rst),
    .v(mat_color_piped),
    .w(mat_spec_color_piped),
    .t(spec_amt_pipe.pipe[1]),
    .one_sub_t(one_sub_spec_amt),
    .lerped(true_mat_color)
  );

  // Combine ray_color and true_mat_color to get new ray color
  fp24_color ray_color_piped;
  pipeline #(.WIDTH(72), .DEPTH(5)) ray_color_pipe (
    .clk(clk),
    .in(ray_color),
    .out(ray_color_piped)
  );
  fp24_color new_color_unpiped;
  fp24_vec3_mul mul_new_ray_color (
    .clk(clk),
    .rst(rst),
    .v(ray_color_piped),
    .w(true_mat_color),
    .prod(new_color_unpiped)
  );
  pipeline #(.WIDTH(72), .DEPTH(31)) new_ray_color_pipe (
    .clk(clk),
    .in(new_color_unpiped),
    .out(new_color)
  );
  
endmodule

`default_nettype wire
