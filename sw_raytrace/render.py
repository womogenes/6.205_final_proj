import subprocess
from PIL import Image

WIDTH, HEIGHT = 32, 18

subprocess.run(["gcc", "main.c", "-o", "a.out", "-lm"], check=True)
subprocess.run(["./a.out"], check=True)

with open("image.bin", "rb") as f:
    data = f.read()

img = Image.frombytes("RGB", (WIDTH, HEIGHT), data)
img.save("output.png")
print("Wrote output.png")

subprocess.run(["rm", "image.bin", "a.out"], check=True)
