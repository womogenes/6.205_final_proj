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

    def set_cam(
        origin: tuple[float] = None,
        forward: tuple[float] = None,
        right: tuple[float] = None,
        up: tuple[float] = None,
    ):
        for cmd, vec in zip([0, 1, 2, 3], [origin, forward, right, up]):
            if vec is None:
                continue

            ser.write((cmd).to_bytes(1, "little"))
            data = make_fp24_vec3(vec)
            ser.write(data.to_bytes(9, "little"))

    set_cam(
        origin=(0, 0, 1),
        forward=(0, 0, 1280/2),
        right=(1, 0, 0),
        up=(0, 1, 0),
    )


if __name__ == "__main__":
    send_program()
