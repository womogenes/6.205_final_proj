// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0x10000;

#define WIDTH 320
#define HEIGHT 180

int count_neighbors(uint8_t* grid, int x, int y);

void _start() {
  // Temporary buffer for double buffering
  uint8_t temp[WIDTH * HEIGHT];
  
  // Initialize with a glider pattern in the center
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = 0x00;
  }
  
  int cx = WIDTH / 2;
  int cy = HEIGHT / 2;
  fb_ptr[cy * WIDTH + cx + 1] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx + 2] = 0xFF;
  fb_ptr[(cy + 2) * WIDTH + cx] = 0xFF;
  fb_ptr[(cy + 2) * WIDTH + cx + 1] = 0xFF;
  fb_ptr[(cy + 2) * WIDTH + cx + 2] = 0xFF;
  
  while (1) {
    // Compute next generation
    for (int y = 0; y < HEIGHT; y++) {
      for (int x = 0; x < WIDTH; x++) {
        int neighbors = count_neighbors((uint8_t*)fb_ptr, x, y);
        int idx = y * WIDTH + x;
        
        if (fb_ptr[idx]) {
          // Cell is alive
          temp[idx] = (neighbors == 2 || neighbors == 3) ? 0xFF : 0x00;
        } else {
          // Cell is dead
          temp[idx] = (neighbors == 3) ? 0xFF : 0x00;
        }
      }
    }
    
    // Copy temp back to framebuffer
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
      fb_ptr[i] = temp[i];
    }
  }

  __asm__ volatile ("ecall");
}

// Count living neighbors with wraparound
int count_neighbors(uint8_t* grid, int x, int y) {
  int count = 0;
  for (int dy = -1; dy <= 1; dy++) {
    for (int dx = -1; dx <= 1; dx++) {
      if (dx == 0 && dy == 0) continue;
      
      int nx = x + dx;
      int ny = y + dy;
      
      // Manual wraparound
      if (nx < 0) nx = WIDTH - 1;
      if (nx >= WIDTH) nx = 0;
      if (ny < 0) ny = HEIGHT - 1;
      if (ny >= HEIGHT) ny = 0;
      
      if (grid[ny * WIDTH + nx]) count++;
    }
  }
  return count;
}

// Compile with: `make program.mem`. See Makefile for details.
