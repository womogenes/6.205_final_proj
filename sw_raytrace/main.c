// Top-level renderer

#include <stdio.h>
#include <stdint.h>

#include "types.h"
#include "utils.h"

#define WIDTH  320
#define HEIGHT 180

uint8_t framebuf[HEIGHT][WIDTH][3];

int main() {
  for (int pixel_v = 0; pixel_v < HEIGHT; pixel_v++) {
    for (int pixel_h = 0; pixel_h < WIDTH; pixel_h++) {
      // RayTracerParams params = 
    }
  }

  int32_t a = 0xFFFFFFFF;
  int32_t b = 0xFFFFFFFF;
  int32_t res = mul16(a, b);
  printf("prod = 0x%x\n", res);

  FILE* f = fopen("image.bin", "wb");
  fwrite(framebuf, 3, WIDTH * HEIGHT, f);
  fclose(f);
}
