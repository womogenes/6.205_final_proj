import subprocess
from PIL import Image

subprocess.run(["gcc", "main.c", "-o", "a.out", "-lm"], check=True)
subprocess.run(["./a.out"], check=True)

with open("image.bin", "rb") as f:
    data = f.read()
    
    WIDTH = round((len(data) // 3)**0.5 * 4/3)
    HEIGHT = len(data) // 3 // WIDTH
    
img = Image.frombytes("RGB", (WIDTH, HEIGHT), data)
img.save("output.png")
print("Wrote output.png")

subprocess.run(["rm", "image.bin", "a.out"], check=True)
