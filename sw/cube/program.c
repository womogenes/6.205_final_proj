// Must include relevant typedefs for compatibility
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0xC00;

#define WIDTH 320
#define HEIGHT 180

#define BG_COLOR 0xFF
#define FG_COLOR 0x00

void _start() __attribute__((section(".text.startup")));

// Simple sine table (0-359 degrees, scaled by 1024)
const int sin_table[360] = {
  0, 18, 36, 54, 71, 89, 107, 125, 143, 160, 178, 195, 213, 230, 248, 265, 282, 299, 316, 333,
  350, 367, 384, 400, 416, 433, 449, 465, 481, 496, 512, 527, 543, 558, 573, 587, 602, 616, 630, 644,
  658, 672, 685, 698, 711, 724, 737, 749, 761, 773, 784, 796, 807, 818, 828, 839, 849, 859, 868, 878,
  887, 896, 904, 912, 920, 928, 935, 943, 949, 956, 962, 968, 974, 979, 984, 989, 994, 998, 1002, 1005,
  1008, 1011, 1014, 1016, 1018, 1020, 1022, 1023, 1023, 1024, 1024, 1024, 1024, 1023, 1023, 1022, 1020, 1018, 1016, 1014,
  1011, 1008, 1005, 1002, 998, 994, 989, 984, 979, 974, 968, 962, 956, 949, 943, 935, 928, 920, 912, 904,
  896, 887, 878, 868, 859, 849, 839, 828, 818, 807, 796, 784, 773, 761, 749, 737, 724, 711, 698, 685,
  672, 658, 644, 630, 616, 602, 587, 573, 558, 543, 527, 512, 496, 481, 465, 449, 433, 416, 400, 384,
  367, 350, 333, 316, 299, 282, 265, 248, 230, 213, 195, 178, 160, 143, 125, 107, 89, 71, 54, 36,
  18, 0, -18, -36, -54, -71, -89, -107, -125, -143, -160, -178, -195, -213, -230, -248, -265, -282, -299, -316,
  -333, -350, -367, -384, -400, -416, -433, -449, -465, -481, -496, -512, -527, -543, -558, -573, -587, -602, -616, -630,
  -644, -658, -672, -685, -698, -711, -724, -737, -749, -761, -773, -784, -796, -807, -818, -828, -839, -849, -859, -868,
  -878, -887, -896, -904, -912, -920, -928, -935, -943, -949, -956, -962, -968, -974, -979, -984, -989, -994, -998, -1002,
  -1005, -1008, -1011, -1014, -1016, -1018, -1020, -1022, -1023, -1023, -1024, -1024, -1024, -1024, -1023, -1023, -1022, -1020, -1018, -1016,
  -1014, -1011, -1008, -1005, -1002, -998, -994, -989, -984, -979, -974, -968, -962, -956, -949, -943, -935, -928, -920, -912,
  -904, -896, -887, -878, -868, -859, -849, -839, -828, -818, -807, -796, -784, -773, -761, -749, -737, -724, -711, -698,
  -685, -672, -658, -644, -630, -616, -602, -587, -573, -558, -543, -527, -512, -496, -481, -465, -449, -433, -416, -400,
  -384, -367, -350, -333, -316, -299, -282, -265, -248, -230, -213, -195, -178, -160, -143, -125, -107, -89, -71, -54, -36, -18
};

int sin_lookup(int angle) {
  while (angle < 0) angle += 360;
  while (angle >= 360) angle -= 360;
  return sin_table[angle];
}

int cos_lookup(int angle) {
  return sin_lookup(angle + 90);
}

// Draw a line using Bresenham's algorithm
void draw_line(int x0, int y0, int x1, int y1) {
  int dx = x1 - x0;
  int dy = y1 - y0;
  
  if (dx < 0) dx = -dx;
  if (dy < 0) dy = -dy;
  
  int sx = x0 < x1 ? 1 : -1;
  int sy = y0 < y1 ? 1 : -1;
  int err = dx - dy;
  
  while (1) {
    if (x0 >= 0 && x0 < WIDTH && y0 >= 0 && y0 < HEIGHT) {
      fb_ptr[y0 * WIDTH + x0] = FG_COLOR;
    }
    
    if (x0 == x1 && y0 == y1) break;
    
    int e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x0 += sx;
    }
    if (e2 < dx) {
      err += dx;
      y0 += sy;
    }
  }
}

void _start() {
  // Cube vertices (scaled by 50 for visibility)
  int vertices[8][3] = {
    {-50, -50, -50},
    {50, -50, -50},
    {50, 50, -50},
    {-50, 50, -50},
    {-50, -50, 50},
    {50, -50, 50},
    {50, 50, 50},
    {-50, 50, 50}
  };
  
  // Cube edges
  int edges[12][2] = {
    {0, 1}, {1, 2}, {2, 3}, {3, 0}, // Back face
    {4, 5}, {5, 6}, {6, 7}, {7, 4}, // Front face
    {0, 4}, {1, 5}, {2, 6}, {3, 7}  // Connecting edges
  };
  
  int angle_x = 0;
  int angle_y = 0;
  int angle_z = 0;
  
  // Animation loop
  while (1) {
    // Clear framebuffer
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
      fb_ptr[i] = BG_COLOR;
    }
    
    // Rotated and projected points
    int projected[8][2];
    
    for (int i = 0; i < 8; i++) {
      int x = vertices[i][0];
      int y = vertices[i][1];
      int z = vertices[i][2];
      
      // Rotate around X axis
      int cos_x = cos_lookup(angle_x);
      int sin_x = sin_lookup(angle_x);
      int y1 = (y * cos_x - z * sin_x) / 1024;
      int z1 = (y * sin_x + z * cos_x) / 1024;
      y = y1;
      z = z1;
      
      // Rotate around Y axis
      int cos_y = cos_lookup(angle_y);
      int sin_y = sin_lookup(angle_y);
      int x1 = (x * cos_y + z * sin_y) / 1024;
      z1 = (-x * sin_y + z * cos_y) / 1024;
      x = x1;
      z = z1;
      
      // Rotate around Z axis
      int cos_z = cos_lookup(angle_z);
      int sin_z = sin_lookup(angle_z);
      x1 = (x * cos_z - y * sin_z) / 1024;
      y1 = (x * sin_z + y * cos_z) / 1024;
      x = x1;
      y = y1;
      
      // Project to 2D (simple perspective)
      int distance = 200;
      int scale = distance * 256 / (distance + z);
      projected[i][0] = WIDTH / 2 + (x * scale) / 256;
      projected[i][1] = HEIGHT / 2 - (y * scale) / 256;
    }
    
    // Draw edges
    for (int i = 0; i < 12; i++) {
      int v0 = edges[i][0];
      int v1 = edges[i][1];
      draw_line(projected[v0][0], projected[v0][1], 
                projected[v1][0], projected[v1][1]);
    }
    
    // Update rotation angles
    angle_x = (angle_x + 1) % 360;
    angle_y = (angle_y + 2) % 360;
    angle_z = (angle_z + 1) % 360;
    
    // Delay for animation speed
    for (volatile int d = 0; d < 100000; d++);
  }
  
  __asm__ volatile ("ecall");
}
