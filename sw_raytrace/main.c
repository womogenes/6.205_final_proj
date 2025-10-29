// Top-level renderer

#include <stdio.h>
#include <stdint.h>

#include "types.h"
#include "utils.h"

#include "ray_caster.c"
#include "ray_tracer.c"

uint8_t framebuf[HEIGHT][WIDTH][3];

int main() {
  Camera cam = (Camera){
    .origin  = {0, 0, 0},
    .forward = {0, 0, -WIDTH / 2},
    .right = {WIDTH / 2, 0, 0},
    .up = {0, HEIGHT / 2, 0},
  };
  
  RayTracerParams params;
  RayTracerResult result;

  for (int frame_idx = 0; frame_idx < 30; frame_idx++) {
    printf("rendering frame %d\n", frame_idx);

    for (int pixel_v = 0; pixel_v < HEIGHT; pixel_v++) {
      for (int pixel_h = 0; pixel_h < WIDTH; pixel_h++) {
        ray_caster(&cam, pixel_h, pixel_v, &params);
        ray_tracer(&params, &result);

        framebuf[pixel_v][pixel_h][0] = framebuf[pixel_v][pixel_h][0] * 0.9 + 0.1 * result.pixel_color.r;
        framebuf[pixel_v][pixel_h][1] = framebuf[pixel_v][pixel_h][1] * 0.9 + 0.1 * result.pixel_color.g;
        framebuf[pixel_v][pixel_h][2] = framebuf[pixel_v][pixel_h][2] * 0.9 + 0.1 * result.pixel_color.b;
      }
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
