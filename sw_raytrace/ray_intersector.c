#include "types.h"
#include "scene_buffer.c"
#include "sphere_intersector.c"
#include "trig_intersector.c"

void ray_intersector(Vec3 ray_dir, Vec3 ray_origin, RayIntersectorResult* result) {
  // Intersect ray with everything in scene buffer
  GeometryIntersectorResult intx_result;

  int any_hit = 0;
  Vec3 hit_pos = (Vec3){0};
  Vec3 hit_norm = (Vec3){0};
  float hit_dist = 0;
  Material hit_mat = (Material){0};

  for (int obj_idx = 0; obj_idx < SCENE_BUFFER_LEN; obj_idx++) {
    Object obj = SCENE_BUFFER[obj_idx];

    // Assume is sphere for now
    if (obj.is_trig) {
      trig_intersector(ray_dir, ray_origin, &obj, &intx_result);
    } else {
      sphere_intersector(ray_dir, ray_origin, &obj, &intx_result);
    }

    if (intx_result.hit && (!any_hit || intx_result.dist < hit_dist)) {
      // Update curent best hit point
      hit_pos = intx_result.hit_pos;
      hit_norm = intx_result.hit_norm;
      hit_dist = intx_result.dist;
      hit_mat = obj.mat;
      any_hit = 1;
    }
  }

  result->any_hit = any_hit;
  result->hit_pos = hit_pos;
  result->hit_norm = hit_norm;
  result->hit_mat = hit_mat;
}
