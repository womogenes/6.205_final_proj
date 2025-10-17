// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0xC00;

#define WIDTH 320
#define HEIGHT 180

int count_neighbors(int x, int y);

void _start() {
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = i % 256;
  }

  // __asm__ volatile ("ecall");
  while (1) {}
}

// python compile.py test_pattern/program.c && cp test_pattern/program.mem ../data/prog.mem
