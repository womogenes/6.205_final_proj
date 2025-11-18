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
        smoothness: float = 0,
        specular_prob: float = 0,
    ):
        self.color = color                              # 72
        self.spec_color = spec_color                    # 72
        self.emit_color = emit_color                    # 72
        self.smoothness = smoothness                    # 24
        self.specular_prob = int(specular_prob * 255)   # 8

    def pack_bits(self):
        # Pack properties into bit fields
        fields = [
            (make_fp24_vec3(self.color), 72),
            (make_fp24_vec3(self.emit_color), 72),
            (make_fp24_vec3(self.spec_color), 72),
            (make_fp24(self.smoothness), 24),
            (self.specular_prob, 8),
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
    ROOM_HEIGHT = 6
    ROOM_DEPTH = 12
    ROOM_WIDTH = 12

    objs = [
        # Light
        Object(
            mat=Material(
                color=(0.8, 0.8, 0.8),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(15, 15, 15),
                smoothness=0.5,
                specular_prob=0.0,
            ),
            sphere_center=(0, ROOM_HEIGHT / 2 + 9.85, ROOM_DEPTH / 2),
            sphere_rad=10,
        ),

        # Ground
        Object(
            mat=Material(
                color=(0.3, 1.0, 0.3),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.5,
                specular_prob=0.0,
            ),
            sphere_center=(0, -100000, 0),
            sphere_rad=100000 - ROOM_HEIGHT / 2,
        ),

        # Ceiling
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(0.0, 0.0, 0.0),
                emit_color=(0.6, 0.6, 0.6),
                smoothness=0.5,
                specular_prob=0.0,
            ),
            sphere_center=(0, 100000, 0),
            sphere_rad=100000 - ROOM_HEIGHT / 2,
        ),

        # Back wall
        Object(
            mat=Material(
                color=(0.8, 0.8, 0.8),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.999,
                specular_prob=1.0,
            ),
            sphere_center=(0, 0, 100000),
            sphere_rad=100000 - ROOM_DEPTH,
        ),

        # Front wall
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.999,
                specular_prob=1.0,
            ),
            sphere_center=(0, 0, -100000),
            sphere_rad=100000 - ROOM_DEPTH,
        ),

        # Left wall
        Object(
            mat=Material(
                color=(1.0, 0.3, 0.3),
                spec_color=(1.0, 0.3, 0.3),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=1.0,
                specular_prob=1.0,
            ),
            sphere_center=(-100000, 0, 0),
            sphere_rad=100000 - ROOM_WIDTH / 2,
        ),

        # Right wall
        Object(
            mat=Material(
                color=(0.3, 0.3, 1.0),
                spec_color=(0.3, 0.3, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=1.0,
                specular_prob=1.0,
            ),
            sphere_center=(100000, 0, 0),
            sphere_rad=100000 - ROOM_WIDTH / 2,
        ),

        # Shiny balls group, matching C version
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.0,
                specular_prob=0.0,
            ),
            sphere_center=(-4, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.2,
                specular_prob=1.0,
            ),
            sphere_center=(-4, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.4,
                specular_prob=1.0,
            ),
            sphere_center=(-2, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.6,
                specular_prob=1.0,
            ),
            sphere_center=(0, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=0.8,
                specular_prob=1.0,
            ),
            sphere_center=(2, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
        Object(
            mat=Material(
                color=(1.0, 1.0, 1.0),
                spec_color=(1.0, 1.0, 1.0),
                emit_color=(0.0, 0.0, 0.0),
                smoothness=1.0,
                specular_prob=1.0,
            ),
            sphere_center=(4, 0, ROOM_DEPTH / 2),
            sphere_rad=0.8,
        ),
    ]

    with open(str(proj_path / "data" / "scene_buffer.mem"), "w") as fout:
        for obj in objs:
            bits, width = obj.pack_bits()
            n_hex_digits = (width + 3) // 4
            fout.write(hex(bits)[2:].zfill(n_hex_digits) + "\n")

    print(f"width: {width}")
