// Pseudorandom number generators

#ifndef PRNG_H
#define PRNG_H

#include <stdint.h>
#include <stdlib.h>

#include "gaussian_lookup.h"
#include "types.h"
#include "utils.h"

uint32_t rand0 = 0xAAAAAAAA;
uint32_t rand1 = 0xBBBBBBBB;
uint32_t rand2 = 0xCCCCCCCC;

uint32_t lfsr32(uint32_t* q) {
  uint32_t bit = ((*q >> 0) ^ (*q >> 10) ^ (*q >> 30) ^ (*q >> 31)) & 1;
  *q = (*q >> 1) | (bit << 31);
  return *q;
}

float randf() {
  // uint32_t bits = rand();
  // return *(float*) &bits;
  return (float)rand() / RAND_MAX;
}

Vec3 prng_sphere() {
  // Vec3 rand_vec = (Vec3){
  //   .x = GAUSSIAN_LOOKUP[lfsr32(&rand0) >> 22],
  //   .y = GAUSSIAN_LOOKUP[lfsr32(&rand1) >> 22],
  //   .z = GAUSSIAN_LOOKUP[lfsr32(&rand2) >> 22],
  // };
  // return norm_vec3(rand_vec);

  float x, y, z;
  do {
    x = (randf() - 0.5) * 2;
    y = (randf() - 0.5) * 2;
    z = (randf() - 0.5) * 2;

    // x = randf() + 1.0f;
    // y = randf() + 1.0f;
    // z = randf() + 1.0f;
    // x = (randf() < 0.5) ? x : -x;
    // y = (randf() < 0.5) ? y : -y;
    // z = (randf() < 0.5) ? z : -z;

    return norm_vec3((Vec3){x, y, z});
  } while (1);
}

#endif
