// Take camera representation and pixel coords, return ray

#include <stdlib.h>

#include "types.h"
#include "utils.h"

void ray_caster(Camera* cam, int pixel_h, int pixel_v, RayTracerParams* out) {
  float dof_dist = 50;
  float dof_blur = 0.5;

  float u = ((pixel_h + 0.5f) / WIDTH) * 2.0f - 1.0f;  // [-1, 1]
  float v = 1.0f - ((pixel_v + 0.5f) / HEIGHT) * 2.0f; // [-1, 1], flipped y

  Vec3 jitter = (Vec3){
    .x = ((float)rand() / RAND_MAX - 0.5f) * dof_blur * 2,
    .y = ((float)rand() / RAND_MAX - 0.5f) * dof_blur * 2,
    .z = 0,
  };

  Vec3 ray_dir_prenorm = add_vec3(
    add_vec3(cam->forward, mul_vec3f(cam->right, u)),
    mul_vec3f(cam->up, v)
  );

  Vec3 ray_dir = norm_vec3(
    add_vec3(ray_dir_prenorm, mul_vec3f(jitter, -1))
  );

  out->ray_origin = add_vec3(cam->origin, jitter);
  out->ray_dir = ray_dir;
  out->pixel_h = pixel_h;
  out->pixel_v = pixel_v;
}
