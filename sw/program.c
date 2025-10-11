// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0x10000;

#define WIDTH 320
#define HEIGHT 180

void _start() {
  // Temporary buffer for double buffering
  uint8_t temp[WIDTH * HEIGHT];
  
  // Initialize with a glider pattern in the center
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = 0b10110100;
  }

  __asm__ volatile ("ecall");
}

// Compile with: `make program.mem`. See Makefile for details.
