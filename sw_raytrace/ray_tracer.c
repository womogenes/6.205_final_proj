#include "types.h"

RayTracerResult ray_tracer(RayTracerParams params) {

  RayTracerResult result;
  result.pixel_color = (Color){0xFF, 0xF0, 0x88};
  result.pixel_h = params.pixel_h;
  result.pixel_v = params.pixel_v;

  return result;
}
