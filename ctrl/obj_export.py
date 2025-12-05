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

def is_sphere(verts, threshold=0.05):
    """Check if vertices form a sphere (>20 unique verts, low std in radii)"""
    unique_verts = np.unique(verts, axis=0)
    if len(unique_verts) <= 20:
        return False
    c = unique_verts.mean(axis=0)
    radii = np.linalg.norm(unique_verts - c, axis=1)
    mean_r = radii.mean()
    std_r = radii.std()
    return (std_r / mean_r) < threshold if mean_r > 0 else False

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
    materials = {}

    if hasattr(scene, "geometry"):
        geoms = scene.geometry.items()
    else:
        geoms = [("default", scene)]

    for _, mesh in geoms:
        verts = mesh.vertices

        # Get material info
        mat_name = None
        if hasattr(mesh, "visual") and hasattr(mesh.visual, "material"):
            mat_name = mesh.visual.material.name if hasattr(mesh.visual.material, "name") else None

        mat_name = mat_name or "default"

        # Build materials dictionary
        if mat_name not in materials:
            mat = mtl.get(mat_name, {})
            color = mat.get("Kd", [1, 1, 1])
            emit_color = mat.get("Ke", [0, 0, 0])
            spec_color = mat.get("Ks", [1, 1, 1])
            Ka = mat.get("Ka", [1, 1, 1])
            Ns = mat.get("Ns", 0.0)

            smoothness = float(Ns) / 1000.0
            spec_prob = sum(Ka) / 3.0

            materials[mat_name] = {
                "color": color,
                "emit_color": emit_color,
                "spec_color": spec_color,
                "smoothness": smoothness,
                "specular_prob": spec_prob
            }

        # Detect sphere or export as triangles
        if is_sphere(verts):
            c, r = sphere_from_vertices(verts)
            objects.append({
                "is_trig": False,
                "sphere_center": c,
                "sphere_rad": r,
                "material": mat_name
            })
        else:
            # Export as triangles: trig=(v0, edge B-A, edge C-A)
            for face in mesh.faces:
                A, B, C = verts[face]
                objects.append({
                    "is_trig": True,
                    "trig": [
                        [round(x, 5) for x in A],
                        [round(x, 5) for x in (B - A)],
                        [round(x, 5) for x in (C - A)]
                    ],
                    "material": mat_name
                })

    out = {
        "max_bounces": max_bounces,
        "camera": camera,
        "materials": materials,
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
