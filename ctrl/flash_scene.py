# We love python <3

from pathlib import Path
import sys

proj_path = Path(__file__).parent.parent

sys.path.append(str(proj_path / "sim"))
from utils import make_fp24, make_fp24_vec3, pack_bits
from make_scene_buffer import Material, Object

import wave
import serial
import sys
import json

from tqdm import tqdm

from struct import unpack
import time

from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("scene", nargs="?", type=str)

args = parser.parse_args()
print(args.scene)

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver


if __name__ == "__main__":
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    # for i in range(100):
    #     ser.write((0).to_bytes(1))
    #     input(i+1)
    # return

    def set_cam(
        origin: tuple[float] = None,
        forward: tuple[float] = None,
        right: tuple[float] = None,
        up: tuple[float] = None,
    ):
        for cmd, vec in zip([0b1_00000_00, 0b1_00000_01, 0b1_00000_10, 0b1_00000_11], [origin, forward, right, up]):
            if vec is None:
                continue
            
            print(f"writing cmd: {cmd}, vec: {vec}")
            ser.write((cmd).to_bytes(1, "little"))
            data = make_fp24_vec3(vec)
            ser.write(data.to_bytes(9, "little"))

    def set_obj(obj_idx: int, obj: Object):
        obj_bits, obj_num_bits = obj.pack_bits()
        print(f"{obj_idx=}")
        ser.write(obj_idx.to_bytes(1))

        obj_num_bytes = ((obj_num_bits + 7) // 8)

        print(f"{obj_num_bits=}, {obj_num_bytes=}")
        ser.write(obj_bits.to_bytes(obj_num_bytes, "little"))

    def set_max_bounces(max_bounces: int):
        ser.write((0x85).to_bytes(1, "little"))
        ser.write(max_bounces.to_bytes(1, "little"))

    def set_num_objs(num_objs: int):
        assert num_objs > 0, "Cannot set zero objects"
        ser.write((0x84).to_bytes(1, "little"))
        ser.write(num_objs.to_bytes(2, "little"))

    with open(args.scene) as fin:
        scene = json.load(fin)

    set_cam(
        origin=scene["camera"]["origin"],
        forward=scene["camera"]["forward"],
        right=scene["camera"]["right"],
        up=scene["camera"]["up"],
    )

    # Flash objects
    objs = scene["objects"]
    for idx, obj in enumerate(objs):
        obj["mat"] = Material(**obj["material"])
        del obj["material"]
        print(f"flashing {idx}, {obj}")
        set_obj(idx, Object(**obj))

    set_num_objs(len(objs))

    set_max_bounces(5)
    # set_num_objs(2)
