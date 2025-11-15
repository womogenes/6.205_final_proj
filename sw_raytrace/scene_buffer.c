// Just a few spheres for now

#include "types.h"

const float sqrt3 = 1.73;

const Object SCENE_BUFFER[] = {
  // Red sphere
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1, 0.3, 0.3},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.5f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {-2, 0, 4},
    .sphere_rad_sq = 1 * 1,
  },
  // Green sphere
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 1, 0.3},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 1.0f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {0, 0, 4},
    .sphere_rad_sq = 1 * 1,
  },
  // Blue sphere
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 0.3, 1},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.0f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {2, 0, 4},
    .sphere_rad_sq = 1 * 1,
  },
  // Green sphere, behind
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 1, 0.3},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.0f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {0, 0, 0.9},
    .sphere_rad_sq = 1 * 1,
  },
  // Skylight
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.5, 1.0, 0.5},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {1, 1, 1},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {0, 500, 0},
    .sphere_rad_sq = 200 * 200,
  },
  // "Ground"
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.85, 0.8, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.1, 0.1, 0.1},
      .smoothness = 1.0f,
      .specular_prob = 0.1f,
    },
    .sphere_center = {0, -2000, 5},
    .sphere_rad_sq = 1999 * 1999,
  },
};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
