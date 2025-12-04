#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>
#include <math.h>

static inline uint32_t mul16(uint32_t a, uint32_t b) {
  // Multiply two 16.16 fixed-point integers
  // Intentionally drop last bit
  
  int32_t a_hi = (int16_t)(a >> 16);
  uint32_t a_lo = a & 0xFFFF;
  int32_t b_hi = (int16_t)(b >> 16);
  uint32_t b_lo = b & 0xFFFF;

  // Compute product of highs and mixed
  int32_t res_hi = a_hi * b_hi;
  int32_t res_mid = a_hi * (int32_t)b_lo + (int32_t)a_lo * b_hi;
  uint32_t res_lo = a_lo * b_lo;

  return (res_hi << 16) + res_mid + (res_lo >> 16);
}

// ===== BASIC MATH =====
float min(float a, float b) {
  return a < b ? a : b;
}

// ===== VECTOR OPERATIONS =====
Vec3 add_vec3(Vec3 a, Vec3 b) {
  return (Vec3){
    .x = a.x + b.x,
    .y = a.y + b.y,
    .z = a.z + b.z,
  };
}
Color add_vec3c(Color a, Color b) {
  return (Color){
    .r = a.r + b.r,
    .g = a.g + b.g,
    .b = a.b + b.b,
  };
}

Vec3 mul_vec3f(Vec3 a, float s) {
  return (Vec3){
    .x = a.x * s,
    .y = a.y * s,
    .z = a.z * s,
  };
}
Color mul_vec3cf(Color a, float s) {
  return (Color){
    .r = a.r * s,
    .g = a.g * s,
    .b = a.b * s,
  };
}
Vec3 mul_vec3v(Vec3 a, Vec3 b) {
  return (Vec3){
    .x = a.x * b.x,
    .y = a.y * b.y,
    .z = a.z * b.z,
  };
}
Color mul_vec3c(Color a, Color b) {
  return (Color){
    .r = a.r * b.r,
    .g = a.g * b.g,
    .b = a.b * b.b,
  };
}

Vec3 sub_vec3(Vec3 a, Vec3 b) {
  return (Vec3){
    .x = a.x - b.x,
    .y = a.y - b.y,
    .z = a.z - b.z,
  };
}

Vec3 norm_vec3(Vec3 v) {
  float mag_sq = v.x * v.x + v.y * v.y + v.z * v.z;
  return mul_vec3f(v, 1 / sqrtf(mag_sq));
}

Vec3 cross_vec3(Vec3 v, Vec3 w) {
  return (Vec3){
    .x = v.y * w.z - v.z * w.y,
    .y = v.z * w.x - v.x * w.z,
    .z = v.x * w.y - v.y * w.x,
  };
}

float lerp(float a, float b, float t) {
  return a * (1 - t) + b * t;
}

Vec3 lerp_vec3(Vec3 a, Vec3 b, float t) {
  return (Vec3){
    .x = lerp(a.x, b.x, t),
    .y = lerp(a.y, b.y, t),
    .z = lerp(a.z, b.z, t),
  };
}
Color lerp_color(Color a, Color b, float t) {
  return (Color){
    .r = lerp(a.r, b.r, t),
    .g = lerp(a.g, b.g, t),
    .b = lerp(a.b, b.b, t),
  };
}

float dot_vec3(Vec3 a, Vec3 b) {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

#endif
