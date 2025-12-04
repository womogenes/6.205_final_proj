#include "types.h"
#include "utils.h"

void trig_intersector(Vec3 ray_dir, Vec3 ray_origin, Object* trig, GeometryIntersectorResult* result) {
  // Intersect ray with a triangle
  Vec3 v0 = trig->trig[0];
  Vec3 v0v1 = trig->trig[1];
  Vec3 v0v2 = trig->trig[2];

  Vec3 pvec = cross_vec3(ray_dir, v0v2);
  float det = dot_vec3(v0v1, pvec);

  float invDet = 1 / det;

  Vec3 tvec = sub_vec3(ray_origin, v0);
  float u = dot_vec3(tvec, pvec) * invDet;
  if (u < 0 || u > 1) {
    result->hit = 0;
    return;
  }

  Vec3 qvec = cross_vec3(tvec, v0v1);
  float v = dot_vec3(ray_dir, qvec) * invDet;
  if (v < 0 || u + v > 1) {
    result->hit = 0;
    return;
  }

  float t = dot_vec3(v0v2, qvec) * invDet;
  if (t <= 0) {
    result->hit = 0;
    return;
  }

  result->hit_pos = add_vec3(mul_vec3f(ray_dir, t), ray_origin);
  result->dist = t;
  result->hit_norm = trig->trig_norm;
  result->hit = 1;
  return;
}
