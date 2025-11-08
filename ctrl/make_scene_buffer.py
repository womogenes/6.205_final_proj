# We love python <3

from pathlib import Path
import sys

proj_path = Path(__file__).parent.parent

sys.path.append(str(proj_path / "sim"))
from utils import make_fp24, make_fp24_vec3, pack_bits

class Material:
    def __init__(
        self,
        color: tuple[float],
        emit_color: tuple[float],
        spec_color: tuple[float] = (0, 0, 0),
        smooth: float = 0,
        specular: float = 0,
    ):
        self.color = color              # 72
        self.spec_color = spec_color    # 72
        self.emit_color = emit_color    # 72
        self.smooth = smooth            # 24
        self.specular = specular        # 24

    def pack_bits(self):
        # Pack properties into bit fields
        fields = [
            (make_fp24_vec3(self.color), 72),
            (make_fp24_vec3(self.emit_color), 72),
            (make_fp24_vec3(self.spec_color), 72),
            (make_fp24(self.smooth), 24),
            (make_fp24(self.specular), 24),
        ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])
    

class Object:
    def __init__(
        self,
        mat: Material,
        sphere_center: tuple[float],
        sphere_rad: float,
        is_trig: bool = False,
        trig: tuple[tuple[float]] = (),
        trig_norm: tuple[float] = (),
    ):
        self.is_trig = is_trig
        self.mat = mat
        self.trig = trig or ((0, 0, 0),) * 3
        self.trig_norm = trig_norm or (0, 0, 0)
        self.sphere_center = sphere_center
        self.sphere_rad_sq = sphere_rad ** 2
        self.sphere_rad_inv = 1 / sphere_rad

    def pack_bits(self):
        fields = [
            (self.is_trig, 1),
            self.mat.pack_bits(),
            *[(make_fp24_vec3(v), 72) for v in self.trig],
            (make_fp24_vec3(self.trig_norm), 72),
            (make_fp24_vec3(self.sphere_center), 72),
            (make_fp24(self.sphere_rad_sq), 24),
            (make_fp24(self.sphere_rad_inv), 24),
        ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])


if __name__ == "__main__":
    mat0 = Material(color=(1, 0.3, 0.3), emit_color=(0.1, 0.1, 0.1))
    mat1 = Material(color=(0.3, 1, 0.3), emit_color=(0.1, 0.1, 0.1))
    mat2 = Material(color=(0.3, 0.3, 1), emit_color=(0.1, 0.1, 0.1))
    mat3 = Material(color=(0.5, 1, 0.5), emit_color=(1, 1, 1))
    mat4 = Material(color=(0.85, 0.8, 1), emit_color=(0.1, 0.1, 0.1))

    objs = [
        Object(mat=mat0, sphere_center=(-2, 1, 7), sphere_rad=2),
        Object(mat=mat1, sphere_center=(0, 0, 5), sphere_rad=1),
        Object(mat=mat2, sphere_center=(1, -0.5, 4), sphere_rad=0.5),
        Object(mat=mat3, sphere_center=(0, 500, 0), sphere_rad=450),
        Object(mat=mat4, sphere_center=(0, -200, 5), sphere_rad=199),
    ]

    # Dump to hex file
    with open(str(proj_path / "data" / "scene_buffer.mem"), "w") as fout:
        for obj in objs:
            bits, width = obj.pack_bits()
            n_hex_digits = (width + 3) // 4
            fout.write(hex(bits)[2:].zfill(n_hex_digits) + "\n")

    print(f"width: {width}")
