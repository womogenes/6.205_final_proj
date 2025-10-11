// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint32_t* const fb_ptr = (volatile uint32_t*) 0x00041000;

void _start() {
  int x = 0x200;
  int y = 0x200;
  int z = x + y;

  *fb_ptr = z;

  __asm__ volatile ("ecall");
}

// Compile with: `make program.mem`. See Makefile for details.
