parameter integer FRAC_WIDTH = 16;
parameter integer FULL_WIDTH = 32;

// ===== NUMBERS + MATH =====
typedef logic signed [FULL_WIDTH-1:0] fixed;
typedef logic signed [FRAC_WIDTH:0] short;     // extra bit for two's complement

// ===== COLORS =====
typedef struct packed {
  logic [7:0] r;
  logic [7:0] g;
  logic [7:0] b;
} color8;

typedef struct packed {
  short r;
  short g;
  short b;
} color;

// ===== VECTOR TYPES =====
typedef struct packed {
  fixed x;
  fixed y;
  fixed z;
} vec3;

typedef struct packed {
  short x;
  short y;
  short z;
} vec3s;
