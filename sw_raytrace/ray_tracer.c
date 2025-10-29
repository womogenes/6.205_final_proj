#include "types.h"
#include "prng.h"

#include "ray_intersector.c"
#include "ray_reflector.c"

void ray_tracer(RayTracerParams* params, RayTracerResult* result) {
  Vec3 ray_pos = params->ray_origin;
  Vec3 ray_dir = params->ray_dir;
  Color ray_color = (Color){ 0, 0, 0 };
  Color income_light = (Color){ 1, 1, 1 };

  // Trace the ray
  RayIntersectorResult hit_result;
  RayReflectorResult ref_result;

  for (int bounce_idx = 0; bounce_idx < 10; bounce_idx++) {
    ray_intersector(ray_dir, ray_pos, &hit_result);
    ray_pos = hit_result.hit_pos;

    if (!hit_result.any_hit) break;
    ray_reflector(&ray_pos, &ray_dir, &hit_result.hit_norm, &ray_color, &income_light, &hit_result.hit_mat);
  }

  if (hit_result.any_hit) {
    result->pixel_color = income_light;
    // result->pixel_color = (Color) {
    //   .r = 128,
    //   .g = 128,
    //   .b = 128,
    // };

  } else {
    // By default, if the ray didn't hit anything, render grey
    result->pixel_color = (Color){
      .r = 32,
      .g = 32,
      .b = 32,
      // .r = (uint8_t)((1 + ray_dir.x) * 128),
      // .g = (uint8_t)((1 + ray_dir.y) * 128),
      // .b = (uint8_t)((1 + ray_dir.z) * 128),
    };
  }

  result->pixel_h = params->pixel_h;
  result->pixel_v = params->pixel_v;
}
