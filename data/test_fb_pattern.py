# Generate a 1280x720 test pattern in frame buffer

FB_ADDR = 0x00004000

mem = bytearray(FB_ADDR + 320*180)

for i in range(len(mem)):
    if i % 2 == 0:
        mem[i] = 0xFF
    else:
        mem[i] = 0x00

with open("./prog.mem", "w") as fout:
    for byte in mem:
        fout.write(f"{byte:02X}\n")
