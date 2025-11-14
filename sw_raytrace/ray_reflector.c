#include "types.h"
#include "utils.h"
#include "prng.h"

void reflect_ray(
  Vec3* ray_dir,
  Vec3* normal,
  Vec3* reflect_dir
) {
  float dot = dot_vec3(*ray_dir, *normal);
  *reflect_dir = add_vec3(
    *ray_dir,
    mul_vec3f(*normal, -2 * dot)
  );
}

// we LOVE pointers
void ray_reflector(
  Vec3* ray_pos,
  Vec3* ray_dir,
  Vec3* normal,
  Color* ray_color,
  Color* income_light,
  Material* mat
) {
  // Assume material is smooth for now
  // Assume entirely random direction

  Vec3 diffuse_dir = norm_vec3(
    add_vec3(prng_sphere(), *normal)
  );
  Vec3 specular_dir;
  reflect_ray(ray_dir, normal, &specular_dir);

  // printf("%f < %f\n", randf(), mat->specular_prob);
  float specular_amt = (randf() < (mat->specular_prob)) ? mat->smoothness : 0;

  Color mat_color = lerp_color(mat->color, mat->spec_color, specular_amt);
  Vec3 new_ray_dir = lerp_vec3(diffuse_dir, specular_dir, specular_amt);
  
  Color new_income_light = mul_vec3c(mat->emit_color, *ray_color);
  *income_light = add_vec3c(new_income_light, *income_light);
  *ray_color = mul_vec3c(*ray_color, mat_color);

  *ray_dir = new_ray_dir;
}
