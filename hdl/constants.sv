// Constants for now are defined above their modules
// e.g. inv_sqrt delay is defined in fp24_inv_sqrt.sv

parameter integer SCENE_BUFFER_DEPTH = 5;

// Math module delay counts
parameter integer INV_SQRT_NR_STAGES = 2;
parameter integer INV_SQRT_STAGE_DELAY = 5;
parameter integer INV_SQRT_DELAY = INV_SQRT_NR_STAGES * INV_SQRT_STAGE_DELAY;

parameter integer SQRT_DELAY = INV_SQRT_DELAY + 1;

parameter integer MAX_BOUNCES = 5;
