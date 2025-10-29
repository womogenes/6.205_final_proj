#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

// ===== SHARED TYPES =====
typedef uint32_t fixed;

typedef struct { fixed x; fixed y; fixed z; } Vec3;
typedef struct { short x; short y; short z; } Vec3s;
typedef struct { uint8_t r; uint8_t g; uint8_t b; } Color;
typedef struct { fixed m[4][4] } Mat4;


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

typedef struct {
  Vec3 origin;
  Vec3 forward;
  Vec3 right;
  Vec3 up;
  uint32_t fov_y;
  uint32_t aspect;
} Camera;

// ===== RAY CASTER TYPES =====
// (same as ray tracer inputs)

#endif
