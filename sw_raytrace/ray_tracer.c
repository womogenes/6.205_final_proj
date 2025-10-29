#include "types.h"

void ray_tracer(RayTracerParams* params, RayTracerResult* out) {
  Vec3 ray_origin = params->ray_origin;
  Vec3 ray_dir = params->ray_dir;

  out->pixel_color = (Color){
    .r = (uint8_t)((ray_dir.x + 1) * 127),
    .g = (uint8_t)((ray_dir.y + 1) * 127),
    .b = (uint8_t)((ray_dir.z + 1) * 127),
  };

  // printf("vector: %f, %f, %f\n", ray_dir.x, ray_dir.y, ray_dir.z);

  out->pixel_h = params->pixel_h;
  out->pixel_v = params->pixel_v;
}
