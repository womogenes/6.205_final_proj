#include "types.h"

void ray_tracer(RayTracerParams* params, RayTracerResult* out) {
  Vec3 ray_origin = params->ray_origin;
  Vec3 ray_dir = params->ray_dir;

  out->pixel_color = (Color){
    .r = ray_dir.x,
    .g = ray_dir.y,
    .b = ray_dir.z,
  };

  printf("vector: %f, %f, %f\n", ray_dir.x, ray_dir.y, ray_dir.z);

  out->pixel_h = params->pixel_h;
  out->pixel_v = params->pixel_v;
}
