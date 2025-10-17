#include "types.c"
#include "blit16_glyphs.h"

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0xC00;

#define WIDTH 320
#define HEIGHT 180

void _start() __attribute__((section(".text.startup")));

void print_char(int x, int y, char c);
void print_str(int x, int y, char* s);

void _start() {
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = 0xFF;
  }

  // Test with just a few characters
  // print_char(10, 90, 'h');
  // print_char(10, 90, 'i');
  print_str(10, 10, "hello world!");

  // __asm__ volatile ("ecall");
  while (1) {}
}

void print_str(int x, int y, char* s) {
  int i = 0;
  while (s[i] != '\0') {
    print_char(x + i * 4, y, s[i]);
    i++;
  }
}

void print_char(int x, int y, char c) {
  // Bounds check
  if (c < 32 || c >= 127) return;

  uint16_t glyph = blit16_Glyphs[c - 32];

  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 3; j++) {
      int pixel_addr = (y + i) * 320 + (x + j);
      int glyph_addr = i * 3 + j;
      fb_ptr[pixel_addr] = (glyph & (1 << glyph_addr)) ? 0x00 : 0xFF;
    }
  }
}
