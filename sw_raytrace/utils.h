#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>

static inline uint32_t __mul16(uint32_t a, uint32_t b) {
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

#endif
