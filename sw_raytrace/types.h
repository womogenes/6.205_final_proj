#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

// ===== SHARED TYPES =====
typedef struct { uint32_t x; uint32_t y; uint32_t z; } Vec3;
typedef struct { uint16_t x; uint16_t y; uint16_t z; } Vec3s;
typedef struct { uint8_t r; uint8_t g; uint8_t b; } Color;


// ===== RAY TRACER TYPES =====
typedef struct {
  Vec3 ray_origin;
  Vec3s ray_dir;
  int pixel_h;
  int pixel_v;
} RayTracerParams;

typedef struct {
  Color pixel_color;
  int pixel_h;
  int pixel_v;
} RayTracerResult;

// ===== RAY CASTER TYPES =====
// (same as ray tracer inputs)

#endif
