#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

#define WIDTH 320
#define HEIGHT 180

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
  Color color;
  Color emit_light;
  float smooth;
  float specular;
} Material;

typedef struct {
  Vec3 origin;
  Vec3 forward;
  Vec3 right;
  Vec3 up;
} Camera;

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
  int hit;
  Vec3 hit_pos;
  Vec3 hit_norm;
  float dist;
} SphereIntersectorResult;

typedef struct {
  int any_hit;    // whether we hit an object
  Vec3 hit_pos;
  Vec3 hit_norm;
  Material hit_mat;
} RayIntersectorResult;

// ===== RAY CASTER TYPES =====
// (same as ray tracer inputs)

// ===== SCENE BUFFER TYPES =====

typedef struct {
  int is_trig;
  Material mat;
  Vec3 trig[3];
  Vec3 trig_norm;
  Vec3 sphere_center;
  float sphere_rad;
} Object;

#endif
