// Just a few spheres for now

#include "types.h"

const float sqrt3 = 1.73;
const int ROOM_HEIGHT = 6;
const int ROOM_DEPTH = 12;
const int ROOM_WIDTH = 12;

const Object SCENE_BUFFER[] = {
  // Light
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.8, 0.8, 0.8},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {15, 15, 15},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {0, ROOM_HEIGHT / 2 + 9.85, ROOM_DEPTH / 2},
    .sphere_rad = 10,
  },
  // Ground
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 1.0, 0.3},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {0, -100000, 0},
    .sphere_rad = 100000 - ROOM_HEIGHT / 2,
  },
  // Ceiling
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {0.0, 0.0, 0.0},
      .emit_color = {0.6, 0.6, 0.6},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {0, 100000, 0},
    .sphere_rad = 100000 - ROOM_HEIGHT / 2,
  },
  // Back wall
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.8, 0.8, 0.8},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.999f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {0, 0, 100000},
    .sphere_rad = 100000 - ROOM_DEPTH,
  },
  // Front wall
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.999f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {0, 0, -100000},
    .sphere_rad = 100000 - ROOM_DEPTH,
  },
  // Left wall
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 0.3, 0.3},
      .spec_color = {1.0, 0.3, 0.3},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 1.0f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {-100000, 0, 0},
    .sphere_rad = 100000 - ROOM_WIDTH / 2,
  },
  // Right wall
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {0.3, 0.3, 1.0},
      .spec_color = {0.3, 0.3, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 1.0f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {100000, 0, 0},
    .sphere_rad = 100000 - ROOM_WIDTH / 2,
  },
  // Shiny balls
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.0f,
      .specular_prob = 0.0f,
    },
    .sphere_center = {-4, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.2f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {-4, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.4f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {-2, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.6f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {-0, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 0.8f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {2, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  },
  (Object){
    .is_trig = 0,
    .mat = (Material){
      .color = {1.0, 1.0, 1.0},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0.0, 0.0, 0.0},
      .smoothness = 1.0f,
      .specular_prob = 1.0f,
    },
    .sphere_center = {4, 0, ROOM_DEPTH / 2},
    .sphere_rad = 0.8,
  }
};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
