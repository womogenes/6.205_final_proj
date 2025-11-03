parameter integer FRAC_WIDTH = 16;
parameter integer FULL_WIDTH = 32;

// ===== NUMBERS + MATH =====
// FIXED-POINT TYPES NOT USED
// typedef logic signed [FULL_WIDTH-1:0] fixed;
// typedef logic signed [FRAC_WIDTH:0] short;     // extra bit for two's complement

typedef struct packed {
  logic sign;
  logic [6:0] exp;
  logic [15:0] mant;
} fp24;

// ===== COLORS =====
typedef struct packed {
  logic [7:0] r;
  logic [7:0] g;
  logic [7:0] b;
} color8;

// ===== VECTOR TYPES =====
typedef struct packed {
  fp24 x;
  fp24 y;
  fp24 z;
} fp24_vec3;
