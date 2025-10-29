// Just a few spheres for now

#include "types.h"

const Object SCENE_BUFFER[] = {
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1, 0.5, 0.5},
      .emit_color = {0.1, 0.1, 0.1},
      .smooth = 1.0f,
      .specular = 0.0f,
    },
    .trig = 0x0,
    .trig_norm = 0x0,
    .sphere_center = {-2, 0, -4},
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
    .trig = 0x0,
    .trig_norm = 0x0,
    .sphere_center = {2, 0, -4},
    .sphere_rad = 1,
  }
};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
