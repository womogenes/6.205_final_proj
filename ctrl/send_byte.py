import wave
import serial
import sys

# Communication Parameters
SERIAL_PORTNAME = "/dev/ttyUSB2"  # CHANGE ME to match your system's serial port name!
BAUD = 115200  # Make sure this matches your UART receiver

def send_wav():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)
    ser.write((0xAF).to_bytes())


if __name__ == "__main__":
    send_wav()
