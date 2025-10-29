#include "types.h"
#include "utils.h"
#include "prng.h"

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

  *ray_dir = norm_vec3(
    add_vec3(prng_sphere(), *normal)
  );
  
  Color new_income_light = mul_vec3c(mat->emit_color, *ray_color);
  *income_light = add_vec3c(new_income_light, *income_light);
  *ray_color = mul_vec3c(*ray_color, mat->color);
}
