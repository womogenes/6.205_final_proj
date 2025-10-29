#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

// #define WIDTH 320
// #define HEIGHT 180

#define WIDTH 32
#define HEIGHT 18

// ===== SHARED TYPES =====
typedef uint32_t fixed;

typedef struct { float x; float y; float z; } Vec3;
typedef struct { float r; float g; float b; } Color;
typedef struct { float m[4][4]; } Mat4;

// ===== DEFINE VECTOR OPERATIONS =====
Vec3 add_vec3(Vec3 a, Vec3 b) {
  return (Vec3){
    .x = a.x + b.x,
    .y = a.y + b.y,
    .z = a.z + b.z,
  };
}

Vec3 mul_vec3f(Vec3 a, float s) {
  return (Vec3){
    .x = a.x * s,
    .y = a.y * s,
    .z = a.z * s,
  };
}

Vec3 mul_vec3v(Vec3 a, Vec3 b) {
  return (Vec3){
    .x = a.x * b.x,
    .y = a.y * b.y,
    .z = a.z * b.z,
  };
}


// ===== RAY TRACER TYPES =====
typedef struct {
  Vec3 ray_origin;
  Vec3 ray_dir;
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
} Camera;

// ===== RAY CASTER TYPES =====
// (same as ray tracer inputs)

#endif
