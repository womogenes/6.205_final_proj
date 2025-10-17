// Must include relevant typedefs for compatibility
typedef unsigned int uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
typedef int int32_t;
typedef short int16_t;

volatile uint8_t* const fb_ptr = (volatile uint8_t*) 0xC00;

#define WIDTH 320
#define HEIGHT 180

void _start() __attribute__((section(".text.startup")));

// Fixed-point math: 10-bit fractional part (scale by 1024)
#define FP_SHIFT 10
#define FP_ONE (1 << FP_SHIFT)

#define BG_COLOR 0xFF
#define FG_COLOR 0x00

// Simple sine lookup table for 0-90 degrees (64 entries)
// Values are in fixed-point format scaled by 1024
const int16_t sin_table[65] = {
    0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240,
    256, 272, 287, 303, 318, 334, 349, 364, 379, 394, 409, 424, 438, 453, 467, 482,
    496, 510, 524, 537, 551, 564, 577, 590, 603, 615, 628, 640, 652, 664, 675, 687,
    698, 709, 720, 730, 741, 751, 761, 771, 780, 790, 799, 808, 816, 825, 833, 841,
    849
};

// Get sine value for angle (0-255 maps to 0-360 degrees)
int fp_sin(uint8_t angle) {
    uint8_t idx = angle & 0x3F; // angle % 64
    int result;

    if (angle < 64) {
        result = sin_table[idx];
    } else if (angle < 128) {
        result = sin_table[64 - idx];
    } else if (angle < 192) {
        result = -sin_table[idx];
    } else {
        result = -sin_table[64 - idx];
    }

    return result;
}

// Get cosine value for angle (0-255 maps to 0-360 degrees)
int fp_cos(uint8_t angle) {
    return fp_sin(angle + 64); // cos(x) = sin(x + 90°)
}

// 3D point structure
typedef struct {
    int x, y, z;
} Point3D;

// 2D point structure
typedef struct {
    int x, y;
} Point2D;

// Cube vertices (in fixed-point, centered at origin)
// Scaled down to fit on screen
#define CUBE_SIZE (FP_ONE / 12)
Point3D cube_vertices[8] = {
    {-CUBE_SIZE, -CUBE_SIZE, -CUBE_SIZE},
    { CUBE_SIZE, -CUBE_SIZE, -CUBE_SIZE},
    { CUBE_SIZE,  CUBE_SIZE, -CUBE_SIZE},
    {-CUBE_SIZE,  CUBE_SIZE, -CUBE_SIZE},
    {-CUBE_SIZE, -CUBE_SIZE,  CUBE_SIZE},
    { CUBE_SIZE, -CUBE_SIZE,  CUBE_SIZE},
    { CUBE_SIZE,  CUBE_SIZE,  CUBE_SIZE},
    {-CUBE_SIZE,  CUBE_SIZE,  CUBE_SIZE}
};

// Cube edges (vertex pairs)
uint8_t cube_edges[12][2] = {
    {0, 1}, {1, 2}, {2, 3}, {3, 0},  // Back face
    {4, 5}, {5, 6}, {6, 7}, {7, 4},  // Front face
    {0, 4}, {1, 5}, {2, 6}, {3, 7}   // Connecting edges
};

// Rotate point around X axis
Point3D rotate_x(Point3D p, uint8_t angle) {
    int cos_a = fp_cos(angle);
    int sin_a = fp_sin(angle);

    Point3D result;
    result.x = p.x;
    result.y = (p.y * cos_a - p.z * sin_a) >> FP_SHIFT;
    result.z = (p.y * sin_a + p.z * cos_a) >> FP_SHIFT;

    return result;
}

// Rotate point around Y axis
Point3D rotate_y(Point3D p, uint8_t angle) {
    int cos_a = fp_cos(angle);
    int sin_a = fp_sin(angle);

    Point3D result;
    result.x = (p.x * cos_a + p.z * sin_a) >> FP_SHIFT;
    result.y = p.y;
    result.z = (-p.x * sin_a + p.z * cos_a) >> FP_SHIFT;

    return result;
}

// Rotate point around Z axis
Point3D rotate_z(Point3D p, uint8_t angle) {
    int cos_a = fp_cos(angle);
    int sin_a = fp_sin(angle);

    Point3D result;
    result.x = (p.x * cos_a - p.y * sin_a) >> FP_SHIFT;
    result.y = (p.x * sin_a + p.y * cos_a) >> FP_SHIFT;
    result.z = p.z;

    return result;
}

// Project 3D point to 2D screen
Point2D project(Point3D p) {
    // Simple perspective projection
    int fov = 3 * FP_ONE; // Field of view
    int z_offset = 5 * FP_ONE; // Distance from camera

    int z = p.z + z_offset;
    if (z == 0) z = 1; // Avoid division by zero

    Point2D result;
    result.x = ((p.x * fov) / z) + WIDTH / 2;
    result.y = ((p.y * fov) / z) + HEIGHT / 2;

    return result;
}

// Draw a pixel
void draw_pixel(int x, int y, uint8_t color) {
    if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
        fb_ptr[y * WIDTH + x] = color;
    }
}

// Draw a line using Bresenham's algorithm
void draw_line(int x0, int y0, int x1, int y1, uint8_t color) {
    int dx = x1 - x0;
    int dy = y1 - y0;

    if (dx < 0) dx = -dx;
    if (dy < 0) dy = -dy;

    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    while (1) {
        draw_pixel(x0, y0, color);

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

// Clear framebuffer
void clear_screen(uint8_t color) {
    for (int i = 0; i < WIDTH * HEIGHT; i++) {
        fb_ptr[i] = color;
    }
}

void _start() {
    uint8_t angle_x = 0;
    uint8_t angle_y = 0;
    uint8_t angle_z = 0;
    int frame_count = 0;

    // Clear screen once at start
    clear_screen(BG_COLOR);

    // Previous frame's projected vertices
    Point2D prev_projected[8];
    int has_prev_frame = 0;

    while (1) {
        // Slow down rotation
        frame_count++;
        if (frame_count < (1<<18)) {
            continue;
        }
        frame_count = 0;

        // Transformed vertices
        Point3D transformed[8];
        Point2D projected[8];

        // Transform and project all vertices
        for (int i = 0; i < 8; i++) {
            Point3D p = cube_vertices[i];

            // Apply rotations
            p = rotate_x(p, angle_x);
            p = rotate_y(p, angle_y);
            p = rotate_z(p, angle_z);

            transformed[i] = p;
            projected[i] = project(p);
        }

        // Erase previous frame (if we have one)
        if (has_prev_frame) {
            for (int i = 0; i < 12; i++) {
                uint8_t v0 = cube_edges[i][0];
                uint8_t v1 = cube_edges[i][1];

                Point2D p0 = prev_projected[v0];
                Point2D p1 = prev_projected[v1];

                draw_line(p0.x, p0.y, p1.x, p1.y, BG_COLOR);
            }
        }

        // Draw current frame
        for (int i = 0; i < 12; i++) {
            uint8_t v0 = cube_edges[i][0];
            uint8_t v1 = cube_edges[i][1];

            Point2D p0 = projected[v0];
            Point2D p1 = projected[v1];

            draw_line(p0.x, p0.y, p1.x, p1.y, FG_COLOR);
        }

        // Save current projected vertices for next frame
        for (int i = 0; i < 8; i++) {
            prev_projected[i] = projected[i];
        }
        has_prev_frame = 1;

        // Update rotation angles
        angle_x += 1;
        angle_y += 1;
        angle_z += 1;
    }
}
