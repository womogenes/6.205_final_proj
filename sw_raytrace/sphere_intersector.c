#include "types.h"
#include "utils.h"

int solve_quadratic(float a, float b, float c, float* x0, float* x1) {
  // Taken from https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
  float discr = b * b - 4 * a * c;
  if (discr < 0) {
    return 0;
  } else {
    float q = (b > 0) ? -0.5 * (b + sqrtf(discr)) : -0.5 * (b - sqrtf(discr));
    *x0 = q / a;
    *x1 = c / q;
  }

  // Ensure x0 is always smaller value
  if (*x0 > *x1) {
    float temp = *x0;
    *x0 = *x1;
    *x1 = temp;
  }
  return 1;
}

void sphere_intersector(Vec3 ray_dir, Vec3 ray_origin, Object* sphere, SphereIntersectorResult* result) {
  // Intersect a ray with a sphere!

  // Ray is parameterized as (ray_origin + t * ray_dir)
  // Sphere: (P - sphere_center)^2 = radius^2

  Vec3 center = sphere->sphere_center;
  float radius = sphere->sphere_rad;

  Vec3 L = sub_vec3(ray_origin, center);
  float a = dot_vec3(ray_dir, ray_dir);
  float b = 2 * dot_vec3(ray_dir, L);
  float c = dot_vec3(L, L) - radius * radius;

  float t0, t1;
  result->hit = solve_quadratic(a, b, c, &t0, &t1);

  // If there is a negative hit, we're cooked
  if (t0 < 0) {
    result->hit = 0;
    return;
  }
  result->dist = t0;

  // Determine hit position
  Vec3 hit_pos = add_vec3(ray_origin, mul_vec3f(ray_dir, t0));
  result->hit_pos = hit_pos;
  result->hit_norm = mul_vec3f(
    sub_vec3(hit_pos, sphere->sphere_center),
    1 / sphere->sphere_rad
  );
}
