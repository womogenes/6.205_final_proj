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


if __name__ == "__main__":
    send_frame()
