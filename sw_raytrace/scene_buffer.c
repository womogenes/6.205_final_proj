// Just a few spheres for now

#include "types.h"

const float sqrt3 = 1.73;

const Object SCENE_BUFFER[] = {
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1, 0, 0},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {-2.5, 0, 10},
    .sphere_rad = 1,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0, 1, 0},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {0, 0, 10},
    .sphere_rad = 1,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0, 0, 1},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {2.5, 0, 10},
    .sphere_rad = 1,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.5, 1.0, 0.5},
      .emit_color = {1, 1, 1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {0, 50, 10},
    .sphere_rad = 45,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1, 1, 1},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .sphere_center = {0, 0, 200},
    .sphere_rad = 190,
  },
};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
