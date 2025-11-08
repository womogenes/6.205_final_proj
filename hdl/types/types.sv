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

// ===== CAMERA =====
typedef struct packed {
  fp24_vec3 origin;
  fp24_vec3 forward;
  fp24_vec3 right;
  fp24_vec3 up;
} camera;

// ===== OBJECTS =====
typedef struct packed {
  fp24_vec3 color;          // 72 bits
  fp24_vec3 emit_color;     // 72 bits
  fp24_vec3 spec_color;     // 72 bits
  fp24 smooth;              // 24 bits
  fp24 specular;            // 24 bits
} material;

typedef struct packed {
  logic is_trig;            // 1 bit
  material mat;             // 264 bits
  fp24_vec3 [2:0] trig;     // 216 bits
  fp24_vec3 trig_norm;      // 72 bits
  fp24_vec3 sphere_center;  // 72 bits
  fp24 sphere_rad_sq;       // 24 bits
  fp24 sphere_rad_inv;      // 24 bits
} object;

// Scene buffer width calculated as sum of bit-widths of `object` fields
parameter integer SCENE_BUFFER_WIDTH = 673;
