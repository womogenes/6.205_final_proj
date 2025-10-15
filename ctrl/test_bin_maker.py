bin_values = []
for i in range(1024):
    bin_values.append(i % 256)

bin_text = bytes(bin_values)

with open("./ctrl/test_pattern.bin", "wb") as fout:
    fout.write(bin_text)
