// Constants for now are defined above their modules
// e.g. inv_sqrt delay is defined in fp24_inv_sqrt.sv

parameter integer MAX_NUM_OBJS = 257;
parameter integer OBJ_IDX_WIDTH = $clog2(MAX_NUM_OBJS);

// ===== FP24 MATH OPS =====

parameter integer FP_EXP_BITS = 7;
parameter integer FP_MANT_BITS = 16;
parameter integer FP_BITS = 1 + FP_EXP_BITS + FP_MANT_BITS;
parameter integer FP_EXP_OFFSET = (1 << (FP_EXP_BITS - 1)) - 1;
 
// Basic math operation delays
parameter integer FP24_ADD_DELAY = 2;
parameter integer FP24_MUL_DELAY = 1;

// Math module delay counts
parameter integer INV_SQRT_NR_STAGES = 2;
parameter integer INV_SQRT_STAGE_DELAY = 5;
parameter integer INV_SQRT_DELAY = INV_SQRT_NR_STAGES * INV_SQRT_STAGE_DELAY;

// empirically 11
parameter integer SQRT_DELAY = INV_SQRT_DELAY + 1;

// ===== FP24 VEC OPS =====
parameter integer VEC3_ADD_DELAY = FP24_ADD_DELAY;  // 2
parameter integer VEC3_MUL_DELAY = FP24_MUL_DELAY;  // 1
parameter integer VEC3_DOT_DELAY = 5;
parameter integer VEC3_SCALE_DELAY = FP24_MUL_DELAY;
parameter integer VEC3_NORM_DELAY = VEC3_DOT_DELAY + INV_SQRT_DELAY + 1;  // 16
parameter integer VEC3_LERP_DELAY = VEC3_SCALE_DELAY + VEC3_ADD_DELAY;
