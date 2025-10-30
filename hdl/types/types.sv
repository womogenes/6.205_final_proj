parameter FRAC_WIDTH = 16;
parameter FULL_WIDTH = 32;

// ===== COLORS =====
typedef struct packed {
  logic [7:0] r;
  logic [7:0] g;
  logic [7:0] b;
} color8;

typedef struct packed {
  logic [FRAC_WIDTH-1:0] r;
  logic [FRAC_WIDTH-1:0] g;
  logic [FRAC_WIDTH-1:0] b;
} color;

// ===== NUMBERS + MATH =====
typedef logic [FULL_WIDTH-1:0] fixed;
typedef logic [FRAC_WIDTH-1:0] short;
