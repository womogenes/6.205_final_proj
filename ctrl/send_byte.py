import wave
import serial
import sys

from tqdm import tqdm

from struct import unpack

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB1"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_wav():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    def write_word(addr: int, word: int):
        assert addr % 4 == 0
        ser.write((addr // 4).to_bytes(4, "little"))
        ser.write(word.to_bytes(4, "little"))

    prog_path = "../sw/gol/program.bin"

    write_word(0xC00, 0)

    for offset in tqdm(range(0, (1<<16)//4)):
        write_word(offset * 4, 0xFF_00_FF_00)

    # with open(prog_path, "rb") as fin:
    #     data = fin.read()
    #     words = unpack(f'<{len(data)//4}I', data)

    #     for idx, word in enumerate(words):
    #         write_word(idx, word)


if __name__ == "__main__":
    send_wav()
