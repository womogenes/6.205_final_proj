// Must include relevant typedefs for compatability
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0x10000;

#define WIDTH 320
#define HEIGHT 180

int count_neighbors(int x, int y);

void _start() {
  // Initialize with an acorn pattern in the center
  for (int i = 0; i < WIDTH * HEIGHT; i++) {
    fb_ptr[i] = 0x00;
  }
  
  int cx = WIDTH / 2;
  int cy = HEIGHT / 2;
  
  // Acorn pattern:
  //  X
  //    X
  // XX  XXX
  fb_ptr[(cy - 1) * WIDTH + cx + 1] = 0xFF;
  fb_ptr[cy * WIDTH + cx + 3] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx + 1] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx + 4] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx + 5] = 0xFF;
  fb_ptr[(cy + 1) * WIDTH + cx + 6] = 0xFF;
  
  // Run simulation forever
  while (1) {
    // Compute next generation: use bit 0 for next state
    // Current state is in bit 7 (0xFF vs 0xFE vs 0x00)
    for (int y = 0; y < HEIGHT; y++) {
      for (int x = 0; x < WIDTH; x++) {
        int neighbors = count_neighbors(x, y);
        int idx = y * WIDTH + x;
        uint8_t alive = fb_ptr[idx] & 0xFE; // 0xFF or 0xFE means alive, 0x00 means dead
        uint8_t next;
        
        if (alive) {
          next = (neighbors == 2 || neighbors == 3) ? 0x01 : 0x00;
        } else {
          next = (neighbors == 3) ? 0x01 : 0x00;
        }
        
        fb_ptr[idx] = (fb_ptr[idx] & 0xFE) | next;
      }
    }
    
    // Copy bit 0 to all bits for display
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
      fb_ptr[i] = (fb_ptr[i] & 0x01) ? 0xFF : 0x00;
    }
  }

  __asm__ volatile ("ecall");
}

// Count living neighbors with wraparound
int count_neighbors(int x, int y) {
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
      
      if (fb_ptr[ny * WIDTH + nx] & 0xFE) count++;
    }
  }
  return count;
}

// Compile with: `make program.mem`. See Makefile for details.
