# We love python <3

from pathlib import Path
import sys

proj_path = Path(__file__).parent.parent

sys.path.append(str(proj_path / "sim"))
from utils import make_fp24, make_fp24_vec3, pack_bits

import wave
import serial
import sys

from tqdm import tqdm

from struct import unpack
import time

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_program():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    # for _ in range(30):
    #     ser.write((0).to_bytes(1))
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

    set_cam(
        origin=(3, 0, -20),
        forward=(0, 0, 1280 // 2 * 8),
        right=(1, 0, 0),
        up=(0, 1, 0),
    )


if __name__ == "__main__":
    send_program()
