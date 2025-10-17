import wave
import serial
import sys

from tqdm import tqdm

from struct import unpack
import time

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_program(prog_path):
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)
    ser.write(bytes([0xAA]))

    with open(prog_path, "rb") as fin:
        data = fin.read()

        # Address 0
        ser.write((0).to_bytes(4, "little"))

        # Message length
        n_bytes = len(data)
        print(f"Writing {n_bytes} bytes...")
        ser.write(n_bytes.to_bytes(4, "little"))

        for b in tqdm(data, ncols=80):
            ser.write(bytes([b]))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: send_program.py <prog.bin>")

    send_program(sys.argv[1])
