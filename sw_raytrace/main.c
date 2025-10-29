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

  float N_FRAMES = 30;

  for (int frame_idx = 0; frame_idx < 30; frame_idx++) {
    printf("rendering frame %d\n", frame_idx);

    for (int pixel_v = 0; pixel_v < HEIGHT; pixel_v++) {
      for (int pixel_h = 0; pixel_h < WIDTH; pixel_h++) {
        ray_caster(&cam, pixel_h, pixel_v, &params);
        ray_tracer(&params, &result);

        uint8_t* pix_r = &(framebuf[pixel_v][pixel_h][0]);
        uint8_t* pix_g = &(framebuf[pixel_v][pixel_h][1]);
        uint8_t* pix_b = &(framebuf[pixel_v][pixel_h][2]);

        *pix_r = 0.875 * (*pix_r) + 0.125 * result.pixel_color.r;
        *pix_g = 0.875 * (*pix_g) + 0.125 * result.pixel_color.g;
        *pix_b = 0.875 * (*pix_b) + 0.125 * result.pixel_color.b;
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
