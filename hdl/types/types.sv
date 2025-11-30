parameter integer FRAC_WIDTH = 16;
parameter integer FULL_WIDTH = 32;

// ===== NUMBERS + MATH =====

// NOTE: declaration of fp moved to constants.sv because dependencies

// ===== COLORS =====
typedef struct packed {
  logic [7:0] r;
  logic [7:0] g;
  logic [7:0] b;
} color8;

typedef struct packed {
  fp r;
  fp g;
  fp b;
} fp_color;

// ===== VECTOR TYPES =====
typedef struct packed {
  fp x;
  fp y;
  fp z;
} fp_vec3;

// ===== CAMERA =====
typedef struct packed {
  fp_vec3 origin;
  fp_vec3 forward;
  fp_vec3 right;
  fp_vec3 up;
} camera;

// ===== OBJECTS =====
typedef struct packed {
  fp_color color;
  fp_color emit_color;
  fp_color spec_color;
  fp smoothness;
  logic [7:0] specular_prob;  // 8 bits
} material;

typedef struct packed {
  logic is_trig;            // 1 bit
  material mat;             // [several] bits
  fp_vec3 [2:0] trig;     // 216 bits
  fp_vec3 trig_norm;
  fp_vec3 sphere_center;
  fp sphere_rad_sq;
  fp sphere_rad_inv;
} object;
