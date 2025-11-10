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

  input logic [47:0] lfsr_seed,

  output fp24_vec3 new_dir,
  output fp24_vec3 new_origin,
  output fp24_color new_color,
  output fp24_color new_income_light,
  output logic reflect_done
);
  fp24_vec3 saved_ray_dir;
  fp24_color saved_ray_color;
  fp24_color saved_income_light;
  fp24_vec3 saved_hit_pos;
  fp24_vec3 saved_hit_normal;
  material saved_hit_mat;
  logic [$clog2(RAY_RFLX_DELAY + 1)-1:0] valid_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      saved_ray_dir <= 0;
      saved_ray_color <= 0;
      saved_income_light <= 0;
      saved_hit_pos <= 0;
      saved_hit_normal <= 0;
      saved_hit_mat <= 0;
      valid_counter <= 0;
    end else begin
      if (hit_valid) begin
        saved_ray_dir <= ray_dir;
        saved_ray_color <= ray_color;
        saved_income_light <= income_light;
        saved_hit_pos <= hit_pos;
        saved_hit_normal <= hit_normal;
        saved_hit_mat <= hit_mat;
        valid_counter <= 0;
      end else begin
        if (valid_counter < RAY_RFLX_DELAY + 1) begin
          valid_counter <= valid_counter + 1;
        end
      end
    end
  end
  assign reflect_done = valid_counter == RAY_RFLX_DELAY;

  fp24_vec3 rng_vec;
  prng_sphere_lfsr prng_sphere (
    .clk(clk),
    .rst(rst),
    .seed(lfsr_seed),
    // .seed(48'h123456789abc),
    .rng_vec(rng_vec)
  );

  fp24_vec3 rng_added;
  fp24_vec3_add diffuse_adder (
    .clk(clk),
    .rst(rst),
    .v(rng_vec),
    .w(saved_hit_normal),
    .is_sub(1'b0),
    .sum(rng_added)
  );

  fp24_vec3 rng_normed;
  fp24_vec3_normalize diffuse_normalizer (
    .clk(clk),
    .rst(rst),
    .v(rng_added),
    .normed(rng_normed)
  );

  // TODO: change when specular reflections implemented
  assign new_dir = rng_normed;
  assign new_origin = saved_hit_pos;
  
  fp24_vec3_mul color_multiplier (
    .clk(clk),
    .rst(rst),
    .v(saved_hit_mat.color),
    .w(saved_ray_color),
    .prod(new_color)
  );

  fp24_color emitted_light;
  fp24_vec3_mul emit_multiplier (
    .clk(clk),
    .rst(rst),
    .v(saved_hit_mat.emit_color),
    .w(saved_ray_color),
    .prod(emitted_light)
  );

  fp24_vec3_add emit_adder (
    .clk(clk),
    .rst(rst),
    .v(emitted_light),
    .w(saved_income_light),
    .sum(new_income_light)
  );
  
endmodule

`default_nettype wire
