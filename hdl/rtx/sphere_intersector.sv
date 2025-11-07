`default_nettype none

module sphere_intersector (
  input wire clk,
  input wire rst,

  input fp24_vec3 ray_origin,
  input fp24_vec3 ray_dir,
  input fp24_vec3 sphere_center,
  input fp24 sphere_rad,

  output logic hit,
  output fp24_vec3 hit_pos,
  output fp24 hit_dist_sq,
  output fp24_vec3 hit_norm,
  output logic hit_valid
);
  // We love sphere intersector
  
endmodule

`default_nettype wire
