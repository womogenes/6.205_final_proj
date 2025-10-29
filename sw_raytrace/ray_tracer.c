#include "types.h"
#include "prng.h"

#include "ray_intersector.c"

void ray_tracer(RayTracerParams* params, RayTracerResult* result) {
  Vec3 ray_origin = params->ray_origin;
  Vec3 ray_dir = params->ray_dir;

  // Trace the ray
  RayIntersectorResult hit_result;
  ray_intersector(ray_dir, ray_origin, &hit_result);

  if (hit_result.any_hit) {
    result -> pixel_color = (Color) {
      .r = 255,
      .g = 255,
      .b = 255,
    };

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
