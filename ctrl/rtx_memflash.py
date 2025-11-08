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

    data = make_fp24_vec3((0, 0, -1))

    # Command (move origin)
    ser.write((0b0000_0000).to_bytes(4, "little"))

    # Message length
    print(f"Writing 9 bytes...")
    ser.write(data.to_bytes(9, "little"))


if __name__ == "__main__":
    send_program()
