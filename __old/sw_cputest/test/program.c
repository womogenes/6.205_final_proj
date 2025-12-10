#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "blit16_glyphs.h"

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0xC00;

#define WIDTH 320
#define HEIGHT 180

void _start() __attribute__((section(".text.startup")));

void print_char(int x, int y, char c) __attribute__((optimize("O1")));
void print_str(int x, int y, char* s) __attribute__((optimize("O1")));

char* itoa10(int n) __attribute__((optimize("O1")));
char* itoa10(int n) {
  static char buf[12];
  char *p = buf + 11;
  int neg = n < 0;
  if (neg) n = -n;
  *p = '\0';
  do *--p = '0' + (n % 10); while (n /= 10);
  if (neg) *--p = '-';
  return p;
}

#define BG_COLOR 0xFF
#define FG_COLOR 0x00

void _start() {
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = BG_COLOR;
  }

  // print_str(10, 10, "hey now 0123");

  int y = 0;
  while (1) {
    print_str(160, 90, itoa10(++y));
  }

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
      fb_ptr[pixel_addr] = (glyph & (1 << glyph_addr)) ? FG_COLOR : BG_COLOR;
    }
  }
}
