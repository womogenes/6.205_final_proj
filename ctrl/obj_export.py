"""Convert Blender .blend files to raytracer JSON scene format"""

import json
import numpy as np
import trimesh
import sys
import subprocess

def mtl_to_dict(mtl_path):
    """Parse MTL file into material dictionary"""
    data, current = {}, None
    with open(mtl_path) as f:
        for line in f:
            parts = line.split()
            if not parts:
                continue
            if parts[0] == "newmtl":
                current = parts[1]
                data[current] = {}
            elif current and parts[0] in ("Kd", "Ks", "Ke", "Ka"):
                data[current][parts[0]] = list(map(float, parts[1:]))
            elif current and parts[0] in ("Ns", "illum"):
                data[current][parts[0]] = float(parts[1])
    return data

def is_sphere(verts, threshold=0.05):
    """
    Check if >20 unique vertices with low radii std deviation
    """
    unique = np.unique(verts, axis=0)
    if len(unique) <= 20:
        return False
    center = unique.mean(axis=0)
    radii = np.linalg.norm(unique - center, axis=1)
    return (radii.std() / radii.mean()) < threshold if radii.mean() > 0 else False

def sphere_from_verts(verts):
    """
    Compute sphere center and radius from vertices
    """
    c = verts.mean(axis=0)
    r = np.linalg.norm(verts - c, axis=1).mean()
    return [round(x, 5) for x in c], float(r)

def convert_obj_to_json(obj_path, mtl_path, out_path, max_bounces=5, camera=None):
    """
    Convert OBJ+MTL to raytracer JSON scene format
    """
    camera = camera or {
        "origin": [0, 0, -25],
        "forward": [0, 1280, 0],
        "up": [0, 0, 2],
        "right": [2, 0, 0]
    }

    mtl = mtl_to_dict(mtl_path)
    scene = trimesh.load(obj_path, split_object="o", group_material=False)
    objects, materials = [], {}
    geoms = scene.geometry.items() if hasattr(scene, "geometry") else [("default", scene)]

    for _, mesh in geoms:
        verts = mesh.vertices

        # Get material name
        mat_name = "default"
        if hasattr(mesh, "visual") and hasattr(mesh.visual, "material") and hasattr(mesh.visual.material, "name"):
            mat_name = mesh.visual.material.name

        # Build materials dictionary once per unique material
        if mat_name not in materials:
            m = mtl.get(mat_name, {})
            materials[mat_name] = {
                "color": m.get("Kd", [1, 1, 1]),
                "emit_color": m.get("Ke", [0, 0, 0]),
                "spec_color": m.get("Ks", [1, 1, 1]),
                "smoothness": m.get("Ns", 0.0) / 1000.0,
                "specular_prob": sum(m.get("Ka", [1, 1, 1])) / 3.0
            }

        # Detect sphere or export as triangles
        if is_sphere(verts):
            c, r = sphere_from_verts(verts)
            objects.append({
                "is_trig": False,
                "sphere_center": c,
                "sphere_rad": r,
                "material": mat_name
            })
        else:
            for face in mesh.faces:
                A, B, C = verts[face]
                objects.append({
                    "is_trig": True,
                    "trig": [[round(x, 5) for x in v] for v in [A, B-A, C-A]],
                    "material": mat_name
                })

    with open(out_path, "w") as f:
        print(f"Number of objects {len(objects)}")
        json.dump({
            "max_bounces": max_bounces,
            "camera": camera,
            "materials": materials,
            "objects": objects
        }, f, indent=2)


if __name__ == "__main__":
    blend_path = sys.argv[1]

    # Blender script: export OBJ+MTL and extract camera with FOV
    subprocess.run(["blender", "-b", blend_path, "--python-expr", """
import bpy, mathutils, math, json

bpy.ops.wm.obj_export(
    filepath='/tmp/output.obj',
    export_materials=True,
    forward_axis='Y',
    up_axis='Z'
)

cam = bpy.data.objects['Camera']
quat = cam.matrix_world.to_quaternion()

# Identity mapping: Blender XYZ = Raytracer XYZ
axis = lambda v: quat @ mathutils.Vector(v)

# Compute forward magnitude from horizontal FOV
aspect = 1280.0 / 720.0
if cam.data.type == 'PERSP':
    angle, fit = cam.data.angle, cam.data.sensor_fit
    h_fov = angle if fit == 'HORIZONTAL' else (
        2 * math.atan(math.tan(angle/2) * aspect) if fit == 'VERTICAL'
        else angle if aspect >= 1 else 2 * math.atan(math.tan(angle/2) * aspect))
    fwd_mag = 0.5 * 1280.0 / math.tan(h_fov / 2)
else:
    fwd_mag = 2560.0

# Extract camera axes in world space (Blender camera: looks down local -Z, up is +Y)
forward = axis((0, 0, -1))  # Camera viewing direction
up = axis((0, 1, 0))        # Camera up direction
right = axis((1, 0, 0))     # Camera right direction

with open('/tmp/camera.json', 'w') as f:
    json.dump({
        'origin': [cam.matrix_world.translation.x, cam.matrix_world.translation.y, cam.matrix_world.translation.z],
        'forward': [x * fwd_mag for x in forward],
        'up': [x * 2 for x in up],
        'right': [x * 2 for x in right],
        'pitch': 0, 'yaw': 0
    }, f)
"""], check=True)

    with open("/tmp/camera.json") as f:
        camera = json.load(f)

    convert_obj_to_json(
        "/tmp/output.obj",
        "/tmp/output.mtl",
        "/tmp/output.json",
        camera=camera
    )
