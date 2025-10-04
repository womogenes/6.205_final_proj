bin_text = b"A" * 1024 * 1024 * 1024

with open("./test_pattern.bin", "wb") as fout:
    fout.write(bin_text)
