import wave
import serial
import sys

from tqdm import tqdm

from struct import unpack
import time

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_wav():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    def write_word(word: int):
        ser.write(word.to_bytes(4, "little"))

    prog_path = "../sw/gol/program.bin"

    ser.write(bytes([0xAA]))

    # Clear part of the frame buffer

    print(f"Sending address")
    write_word(0xC00)

    print(f"Sending length")
    write_word(320*90)

    print(f"Sending bytestream...")
    for _ in tqdm(range(320*90), ncols=80):
        ser.write(bytes([0xFF]))

    # for i in range(256):
    #     ser.write((i).to_bytes(1, "little"))
    #     time.sleep(0.01)

    # for offset in tqdm(range(0, (1<<16)//4)):
    #     write_word(offset * 4, 0xFF_00_FF_00)

    # with open(prog_path, "rb") as fin:
    #     data = fin.read()
    #     words = unpack(f'<{len(data)//4}I', data)

    #     for idx, word in enumerate(words):
    #         write_word(idx, word)


if __name__ == "__main__":
    send_wav()
