// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0x41000;

void _start() {
  // Fill every other cell with 0xFF
  for (int i = 0; i < 320; i++) {
    *(fb_ptr + i) = (i % 2) ? 0xFF : 0x00;
  }

  while (1) { };
  __asm__ volatile ("ecall");
}

// Compile with: `make program.mem`. See Makefile for details.
