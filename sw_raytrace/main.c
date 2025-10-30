// Top-level renderer

#include <stdio.h>
#include <stdint.h>

#include "types.h"
#include "utils.h"

#include "ray_caster.c"
#include "ray_tracer.c"

uint8_t fb[HEIGHT][WIDTH][3];
float fb_float[HEIGHT][WIDTH][3];

int main() {
  Camera cam = (Camera){
    .origin  = {0, 0, 0},
    .forward = {0, 0, WIDTH / 2},
    .right = {WIDTH / 2, 0, 0},
    .up = {0, HEIGHT / 2, 0},
  };
  
  RayTracerParams params;
  RayTracerResult result;

  // float t = 0.80;
  const int N_FRAMES = 60;

  for (int frame_idx = 0; frame_idx < N_FRAMES; frame_idx++) {
    printf("rendering frame %d\n", frame_idx);

    for (int pixel_v = 0; pixel_v < HEIGHT; pixel_v++) {
      for (int pixel_h = 0; pixel_h < WIDTH; pixel_h++) {
        ray_caster(&cam, pixel_h, pixel_v, &params);
        ray_tracer(&params, &result);

        fb_float[pixel_v][pixel_h][0] += result.pixel_color.r;
        fb_float[pixel_v][pixel_h][1] += result.pixel_color.g;
        fb_float[pixel_v][pixel_h][2] += result.pixel_color.b;

        // uint8_t* pix_r = &(fb[pixel_v][pixel_h][0]);
        // uint8_t* pix_g = &(fb[pixel_v][pixel_h][1]);
        // uint8_t* pix_b = &(fb[pixel_v][pixel_h][2]);

        // *pix_r = t * (*pix_r) + (1 - t) * result.pixel_color.r;
        // *pix_g = t * (*pix_g) + (1 - t) * result.pixel_color.g;
        // *pix_b = t * (*pix_b) + (1 - t) * result.pixel_color.b;
      }
    }

    for (int pixel_v = 0; pixel_v < HEIGHT; pixel_v++) {
      for (int pixel_h = 0; pixel_h < WIDTH; pixel_h++) {
        for (int channel = 0; channel < 3; channel++) {
          fb[pixel_v][pixel_h][channel] = fb_float[pixel_v][pixel_h][channel] / N_FRAMES;
        }
      }
    }
  }

  int32_t a = 0xFFFFFFFF;
  int32_t b = 0xFFFFFFFF;
  int32_t res = mul16(a, b);
  printf("prod = 0x%x\n", res);

  FILE* f = fopen("image.bin", "wb");
  fwrite(fb, 3, WIDTH * HEIGHT, f);
  fclose(f);
}
