# We love python <3

from pathlib import Path

from argparse import ArgumentParser
import json
import numpy as np

proj_path = Path(__file__).parent.parent
import sys
sys.path.append(str(proj_path / "sim"))

from utils import make_fp, make_fp_vec3, pack_bits, FP_BITS, FP_VEC3_BITS

parser = ArgumentParser()
parser.add_argument("scene", nargs="?", type=str)

args = parser.parse_args()

class Material:
    def __init__(
        self,
        color: tuple[float],
        emit_color: tuple[float] = (0, 0, 0),
        spec_color: tuple[float] = None,
        smoothness: float = 0,
        specular_prob: float = 0,
        **kwargs,
    ):
        self.color = color
        self.spec_color = spec_color or color
        self.emit_color = emit_color
        self.smoothness = smoothness
        self.specular_prob = int(specular_prob * 255)   # 8

    def pack_bits(self):
        # Pack properties into bit fields
        fields = [
            (make_fp_vec3(self.color), FP_VEC3_BITS),
            (make_fp_vec3(self.emit_color), FP_VEC3_BITS),
            (make_fp_vec3(self.spec_color), FP_VEC3_BITS),
            (make_fp(self.smoothness), FP_BITS),
            (self.specular_prob, 8),
        ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])
    

class Object:
    def __init__(
        self,
        mat: Material,
        sphere_center: tuple[float] = (),
        sphere_rad: float = 1,
        is_trig: bool = False,
        trig: tuple[tuple[float]] = None,
        **kwargs,
    ):
        self.is_trig = is_trig
        self.mat = mat
        self.trig = trig or ((0, 0, 0),) * 3

        if trig is not None:
            self.trig_norm = np.cross(trig[1], trig[2]).astype(float)
            self.trig_norm /= np.linalg.norm(self.trig_norm)
        else:
            self.trig_norm = (0, 0, 0)

        self.sphere_center = sphere_center or (0, 0, 0)
        self.sphere_rad_sq = sphere_rad ** 2 or 0
        self.sphere_rad_inv = 1 / sphere_rad or 0

    def pack_bits(self):
        fields = [
            (self.is_trig, 1),
            self.mat.pack_bits(),
            *[(make_fp_vec3(v), 72) for v in self.trig],
            (make_fp_vec3(self.trig_norm), 72)
            ] if self.is_trig else [
                (self.is_trig, 1),
                self.mat.pack_bits(),
                (make_fp_vec3(self.sphere_center), 72),
                (make_fp(self.sphere_rad_sq), 24),
                (make_fp(self.sphere_rad_inv), 24),
                (0, 168)
            ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])


if __name__ == "__main__":
    with open(args.scene) as fin:
        scene = json.load(fin)

    objs = scene["objects"]
    obj_objs = []
    for idx, obj in enumerate(objs):
        obj["mat"] = Material(**scene["materials"][obj["material"]])
        obj_objs.append(Object(**obj))
    objs = obj_objs


    with open(str(proj_path / "data" / "scene_buffer.mem"), "w") as fout:
        for obj in objs:
            bits, width = obj.pack_bits()
            n_hex_digits = (width + 3) // 4
            fout.write(hex(bits)[2:].zfill(n_hex_digits) + "\n")

    print(f"width: {width}")
    print(f"depth: {len(objs)}")
