// Take camera representation and pixel coords, return ray

#include "types.h"

void ray_caster(Camera* cam, int pixel_h, int pixel_v, RayTracerParams* out) {
  float u = ((pixel_h + 0.5f) / WIDTH) * 2.0f - 1.0f;  // [-1, 1]
  float v = 1.0f - ((pixel_v + 0.5f) / HEIGHT) * 2.0f; // [-1, 1], flipped y

  Vec3 ray_dir = normalize(
    add_vec3(
      add_vec3(cam->forward, mul_vec3f(cam->right, u)),
      mul_vec3f(cam->up, v)
    )
  );

  out->ray_origin = cam->origin;
  out->ray_dir = ray_dir;
  out->pixel_h = pixel_h;
  out->pixel_v = pixel_v;
}
