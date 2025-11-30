// Constants for now are defined above their modules
// e.g. inv_sqrt delay is defined in fp_inv_sqrt.sv

parameter integer MAX_NUM_OBJS = 257;
parameter integer OBJ_IDX_WIDTH = $clog2(MAX_NUM_OBJS);

// ===== FP MATH OPS =====

parameter integer FP_EXP_BITS = 7;
parameter integer FP_EXP_OFFSET = (1 << (FP_EXP_BITS - 1)) - 1;
parameter integer FP_MANT_BITS = 16;

parameter integer FP_BITS = 1 + FP_EXP_BITS + FP_MANT_BITS;
parameter integer FP_VEC3_BITS = 3 * FP_BITS;
 
// Basic math operation delays
parameter integer FP_ADD_DELAY = 2;
parameter integer FP_MUL_DELAY = 1;

// Math module delay counts
parameter integer INV_SQRT_NR_STAGES = 2;
parameter integer INV_SQRT_STAGE_DELAY = 5;
parameter integer INV_SQRT_DELAY = INV_SQRT_NR_STAGES * INV_SQRT_STAGE_DELAY;

// empirically 11
parameter integer SQRT_DELAY = INV_SQRT_DELAY + 1;

// ===== FP VEC OPS =====
parameter integer VEC3_ADD_DELAY = FP_ADD_DELAY;  // 2
parameter integer VEC3_MUL_DELAY = FP_MUL_DELAY;  // 1
parameter integer VEC3_DOT_DELAY = 5;
parameter integer VEC3_SCALE_DELAY = FP_MUL_DELAY;
parameter integer VEC3_NORM_DELAY = VEC3_DOT_DELAY + INV_SQRT_DELAY + 1;  // 16
parameter integer VEC3_LERP_DELAY = VEC3_SCALE_DELAY + VEC3_ADD_DELAY;
