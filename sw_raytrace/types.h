#ifndef TYPES_H
#define TYPES_H

#include <stdint.h>

#define HD 1

#if HD
  #define WIDTH 1280
  #define HEIGHT 720
#else
  #define WIDTH 320
  #define HEIGHT 180
#endif

// ===== SHARED TYPES =====
typedef uint32_t fixed;

typedef struct { float x; float y; float z; } Vec3;
typedef struct { float r; float g; float b; } Color;
typedef struct { float m[4][4]; } Mat4;

// ===== RAY TRACER TYPES =====
typedef struct {
  Color color;
  Color spec_color;   // specular color
  Color emit_color;   // emission color
  float specular_prob;
  float smoothness;
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

typedef struct {
  Vec3 ray_pos;
  Vec3 ray_dir;
  Vec3 normal;

  Color ray_color;
  Color income_light;
  Material mat;
} RayreflectorParams;

typedef struct {
  
} RayReflectorResult;

// ===== RAY CASTER TYPES =====pa
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
