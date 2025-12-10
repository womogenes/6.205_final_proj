// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint32_t* const fb_ptr = (volatile uint32_t*) 0xC00;

void _start() {
  int x = 1;
  int y = 1;

  for (int i = 0; i < 10; i++) {
    x = x + y;

    // Swap the values
    x ^= y;
    y ^= x;
    x ^= y;
  }

  // Expect 89
  *fb_ptr = x;

  __asm__ volatile ("ecall");
}
