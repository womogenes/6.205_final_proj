// Take the scene and pack it into 649-bit fields for scene_buffer.sv

#include "types.h"
#include "scene_buffer.c"

uint32_t make_fp24(float f) {
  // Turn a regular C float into fp24 format
  // Out-of-range stuff will get clipped
  uint32_t f_bits = *(int*) &f;

  // Read exponent
  int exp_fp32 = (f_bits >> 23) & 0xFF;
  int exp_fp24 = (exp_fp32 - 127 + 63) & 0x7F;

  // Read mantissa
  int mant_fp24 = (f_bits >> (23 - 16)) & 0xFFFF;

  // Sign bit
  int sign_fp24 = f_bits >> 31;

  return (sign_fp24 << 31) + (exp_fp24 << 16) + mant_fp24;
}

void pack_material(Material mat, uint8_t arr) {
  // Pack material into array
}

int main() {
  // Pack scene buffer into lines that are heeeella long
}
