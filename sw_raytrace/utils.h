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

// ===== VECTOR OPERATIONS =====
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

float dot_vec3(Vec3 a, Vec3 b) {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

#endif
