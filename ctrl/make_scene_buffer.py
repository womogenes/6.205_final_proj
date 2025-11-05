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
        spec_color: tuple[float],
        emit_color: tuple[float],
        smooth: float,
        specular: float
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
            (make_fp24_vec3(self.spec_color), 72),
            (make_fp24_vec3(self.emit_color), 72),
            (make_fp24(self.smooth), 24),
            (make_fp24(self.specular), 24),
        ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])
    

class Object:
    def __init__(
        self,
        is_trig: bool,
        mat: Material,
        trig: tuple[tuple[float]],
        trig_norm: tuple[float],
        sphere_center: tuple[float],
        sphere_rad: float,
    ):
        self.is_trig = is_trig
        self.mat = mat
        self.trig = trig or ((0, 0, 0),) * 3
        self.trig_norm = trig_norm or (0, 0, 0)
        self.sphere_center = sphere_center
        self.sphere_rad = sphere_rad

    def pack_bits(self):
        fields = [
            (self.is_trig, 1),
            self.mat.pack_bits(),
            *[(make_fp24_vec3(v), 72) for v in self.trig],
            (make_fp24_vec3(self.trig_norm), 72),
            (make_fp24_vec3(self.sphere_center), 72),
            (make_fp24(self.sphere_rad), 24),
        ]
        return pack_bits(fields, msb=True), sum([width for _, width in fields])


if __name__ == "__main__":
    mat0 = Material(
        color=(1, 1, 1),
        spec_color=(1, 1, 1),
        emit_color=(1, 1, 1),
        smooth=1,
        specular=0,
    )

    obj0 = Object(
        is_trig=False,
        mat=mat0,
        trig=None,
        trig_norm=None,
        sphere_center=(0, 0, 5),
        sphere_rad=1,
    )

    # Dump to hex file
    with open(str(proj_path / "data" / "scene_buffer.mem"), "w") as fout:
        for obj in [obj0]:
            bits, width = obj.pack_bits()
            n_hex_digits = (width + 3) // 4
            fout.write(hex(bits)[2:].zfill(n_hex_digits) + "\n")
