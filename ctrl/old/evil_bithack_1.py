import numpy as np
import matplotlib.pyplot as plt
import math
import random
from tqdm import tqdm

def make_fp24(x: float):
    """
    Convert Python float to 24-bit fp24 value
    """
    if x == 0:
        return 0
    
    sign = int(x < 0)
    value = abs(x)

    exp = int(math.floor(math.log2(value)))
    exp_biased = exp + 63
    assert 0 <= exp_biased <= 127, f"FP24 only supports exponents between -63 and 64, got {x} ({exp=})"

    frac = value / (2 ** exp)

    mant = int((frac - 1.0) * (1 << 16) + 0.5)
    return (sign << 23) | (exp_biased << 16) | mant

def convert_fp24(f: int):
    """
    Convert 24-bit fp24 value to Python float
    """
    if f == 0:
        return 0
    
    sign = -1 if (f >> 23) & 1 else 1
    exp = ((f >> 16) & 0x7F) - 63
    mant = 1 + (f & 0xFFFF) / (1 << 16)

    return sign * (2 ** exp) * mant

delta = 2**12
errors = []
consts = []
minerror = float("inf")
minconst = 0
for diff in tqdm(range(-delta, delta)):
    num_samples = 1000
    random.seed("wtf")
    const = 0x5e6a0a + diff
    total_error = 0
    for i in range(num_samples):
        x = 2 ** (random.random() * 127 - 63)
        as_bin = make_fp24(x)
        evil = const - (as_bin >> 1)
        res = convert_fp24(evil)
        correct = 1 / math.sqrt(x)
        # print(f"{res=} {correct=}")
        error = abs((correct - res) / correct) * 100
        total_error += error
    avg_error = total_error / num_samples
    if (avg_error < minerror):
        minconst = const
        minerror = avg_error
    errors.append(avg_error)
    consts.append(const)

plt.plot(consts, errors)
# print(consts, errors)
print(f"{minconst=:x}")
plt.savefig("ctrl/evil_graph.png")