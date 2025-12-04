#include "types.h"

const float sqrt3 = 1.73;
const int ROOM_HEIGHT = 6;
const int ROOM_DEPTH = 12;
const int ROOM_WIDTH = 12;

const Object SCENE_BUFFER[] = {

  // Light tri 1
  {
    .is_trig = 1,
    .mat = {
      .color = {0.8, 0.8, 0.8},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {15, 15, 15},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {-2, ROOM_HEIGHT/2 - 0.125f, ROOM_DEPTH/2 - 2},
      {4, 0, 0},
      {0, 0, 4}
    },
    .trig_norm = {0, -1, 0},
  },

  // Light tri 2
  {
    .is_trig = 1,
    .mat = {
      .color = {0.8, 0.8, 0.8},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {15, 15, 15},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {2, ROOM_HEIGHT/2 - 0.125f, ROOM_DEPTH/2 + 2},
      {-4, 0, 0},
      {0, 0, -4}
    },
    .trig_norm = {0, -1, 0},
  },

  // Ground
  {
    .is_trig = 1,
    .mat = {
      .color = {0.3, 1.0, 0.3},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0, 0, 0},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {-ROOM_WIDTH/2, -ROOM_HEIGHT/2, ROOM_DEPTH},
      {0, 0, -ROOM_DEPTH * 2},
      {ROOM_WIDTH * 2, 0, 0}
    },
    .trig_norm = {0, 1, 0},
  },

  // Ceiling
  {
    .is_trig = 1,
    .mat = {
      .color = {1.0, 1.0, 1.0},
      .spec_color = {0, 0, 0},
      .emit_color = {0.6, 0.6, 0.6},
      .smoothness = 0.5f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {-ROOM_WIDTH/2, ROOM_HEIGHT/2, ROOM_DEPTH},
      {ROOM_WIDTH * 2, 0, 0},
      {0, 0, -ROOM_DEPTH * 2}
    },
    .trig_norm = {0, -1, 0},
  },

  // Back wall
  {
    .is_trig = 1,
    .mat = {
      .color = {0.8, 0.8, 0.8},
      .spec_color = {1.0, 1.0, 1.0},
      .emit_color = {0, 0, 0},
      .smoothness = 0.999f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {-ROOM_WIDTH/2, -ROOM_HEIGHT/2, ROOM_DEPTH},
      {ROOM_WIDTH * 2, 0, 0},
      {0, ROOM_HEIGHT * 2, 0}
    },
    .trig_norm = {0, 0, -1},
  },

  // Left wall
  {
    .is_trig = 1,
    .mat = {
      .color = {1.0, 0.3, 0.3},
      .spec_color = {1.0, 0.3, 0.3},
      .emit_color = {0, 0, 0},
      .smoothness = 1.0f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {-ROOM_WIDTH/2, -ROOM_HEIGHT/2, ROOM_DEPTH},
      {0, ROOM_HEIGHT * 2, 0},
      {0, 0, -ROOM_DEPTH * 2}
    },
    .trig_norm = {1, 0, 0},
  },

  // Right wall
  {
    .is_trig = 1,
    .mat = {
      .color = {0.3, 0.3, 1.0},
      .spec_color = {0.3, 0.3, 1.0},
      .emit_color = {0, 0, 0},
      .smoothness = 1.0f,
      .specular_prob = 0.0f,
    },
    .trig = {
      {ROOM_WIDTH/2, -ROOM_HEIGHT/2, ROOM_DEPTH},
      {0, 0, -ROOM_DEPTH * 2},
      {0, ROOM_HEIGHT * 2, 0}
    },
    .trig_norm = {-1, 0, 0},
  },

};

const int SCENE_BUFFER_LEN = sizeof(SCENE_BUFFER) / sizeof(SCENE_BUFFER[0]);
