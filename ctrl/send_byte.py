import wave
import serial
import sys

from tqdm import tqdm

from struct import unpack
import time

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_frame():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    def write_word(word: int):
        ser.write(word.to_bytes(4, "little"))

    ser.write(bytes([0xAA]))

    print(f"Sending address")
    write_word(0xC00)

    print(f"Sending length")
    write_word(320*180)

    print(f"Sending bytestream...")
    for y in range(180):
        for x in range(320):
            d = (y-90)**2 + (x-160)**2
            if d < 90**2:
                ser.write((int(d / 90**2 * 0xFF) & 0xFF).to_bytes(1, "little"))
            else:
                ser.write(bytes([0b11_111_111]))

def send_program():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)
    ser.write(bytes([0xAA]))

    prog_path = "../sw/test_pattern/program.bin"

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
            time.sleep(0.1)


if __name__ == "__main__":
    # send_frame()
    send_program()
