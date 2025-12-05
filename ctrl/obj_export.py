"""
Convert .blend file to a json for use in flashing
"""

import json
import numpy as np
import trimesh
import sys

import subprocess

def mtl_to_dict(mtl_path):
    """
    Parse material file into dictionary
    """
    data = {}
    current = None
    with open(mtl_path, "r") as f:
        for line in f:
            if line.startswith("newmtl"):
                current = line.split()[1].strip()
                data[current] = {}
            elif current:
                parts = line.split()
                if not parts:
                    continue
                key, vals = parts[0], parts[1:]
                if key in ("Kd", "Ks", "Ke", "Ka"):
                    data[current][key] = list(map(float, vals))
                elif key in ("Ns", "illum"):
                    data[current][key] = float(vals[0])
    return data

def sphere_from_vertices(verts):
    """
    Assuming `verts` is an (N, 3) array of (uniform) points on a sphere,
        find center and radius by taking mean + finding avg distance
    """
    c = verts.mean(axis=0)
    r = np.linalg.norm(verts - c, axis=1).mean()
    return [round(x, 5) for x in c], float(r)

def convert_obj_to_json(
    obj_path,
    mtl_path,
    out_path,
    max_bounces=5,
    camera=None,
):
    if camera is None:
        camera = {
            "origin": [0, 0, -25],
            "forward": [0, 0, 1280],
            "up": [0, 2, 0],
            "right": [2, 0, 0],
        }

    mtl = mtl_to_dict(mtl_path)
    scene = trimesh.load(obj_path, split_object="o", group_material=False)
    objects = []

    if hasattr(scene, "geometry"):
        geoms = scene.geometry.items()
    else:
        geoms = [("default", scene)]

    for name, mesh in geoms:
        verts = mesh.vertices
        c, r = sphere_from_vertices(verts)

        # Get material name from mesh visual
        mat_name = None
        if hasattr(mesh, "visual") and hasattr(mesh.visual, "material"):
            mat_name = mesh.visual.material.name if hasattr(mesh.visual.material, "name") else None

        mat = mtl.get(mat_name, {}) if mat_name else {}
        color = mat.get("Kd", [1, 1, 1])
        emit_color = mat.get("Ke", [0, 0, 0])
        spec_color = mat.get("Ks", [1, 1, 1])
        Ka = mat.get("Ka", [1, 1, 1])
        Ns = mat.get("Ns", 0.0)
        illum = mat.get("illum", 0.0)

        smoothness = float(Ns) / 1000.0
        spec_prob = sum(Ka) / 3.0  # mean Ka RGB is specular probability

        obj = {
            "is_trig": 0,
            "sphere_center": c,
            "sphere_rad": r,
            "material": {
                "color": color,
                "emit_color": emit_color,
                "spec_color": spec_color,
                "smoothness": smoothness,
                "specular_prob": spec_prob
            }
        }

        objects.append(obj)

    out = {
        "max_bounces": max_bounces,
        "camera": camera,
        "objects": objects
    }

    with open(out_path, "w") as f:
        json.dump(out, f, indent=2)


if __name__ == "__main__":
    # Yeah I'm lazy, will add argparse later
    blend_path = sys.argv[1]

    subprocess.run([
        "blender", "-b", blend_path, "--python-expr",
        "import bpy; bpy.ops.wm.obj_export(filepath='/tmp/output.obj', export_materials=True)"
    ], check=True)

    convert_obj_to_json(
        "/tmp/output.obj",
        "/tmp/output.mtl",
        "/tmp/output.json"
    )
