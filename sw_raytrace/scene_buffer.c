// Just a few spheres for now

#include "types.h"

const float sqrt3 = 1.73;

const Object SCENE_BUFFER[] = {
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1, 0.3, 0.3},
      .emit_color = {1, 1, 1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {0, 0, 500},
    .sphere_rad = 240,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.8, 0.2, 0},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {50, 0, 180},
    .sphere_rad = 75,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 0.3, 1},
      .emit_color = {10, 10, 10},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {50, 0, 105},
    .sphere_rad = 20,
  },
  // // Skylight
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.5, 1.0, 0.5},
      .emit_color = {0, 0, 0},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {10, 0, 30},
    .sphere_rad = 5,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.85, 0.8, 1.0},
      .emit_color = {10, 10, 10},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {-500, 0, 100},
    .sphere_rad = 200,
  },
};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
