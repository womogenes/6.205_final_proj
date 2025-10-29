// Top-level renderer

#include <stdio.h>
#include <stdint.h>

#include "utils.h"

#define WIDTH  320
#define HEIGHT 180

uint8_t framebuf[HEIGHT][WIDTH][3];

int main() {
  for (int i = 0; i < HEIGHT; i++) {
    for (int j = 0; j < WIDTH; j++) {
      if ((i + j) % 2) {
        framebuf[i][j][0] = 0xFF;
        framebuf[i][j][1] = 0xFF;
        framebuf[i][j][2] = 0xFF;
      }
    }
  }

  int32_t a = 0xFFFFFFFF;
  int32_t b = 0xFFFFFFFF;
  int32_t res = __mul16(a, b);
  printf("prod = 0x%x\n", res);

  FILE* f = fopen("image.bin", "wb");
  fwrite(framebuf, 3, WIDTH * HEIGHT, f);
  fclose(f);
}
