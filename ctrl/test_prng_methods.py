import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.use("TkAgg")
import math
import random
from tqdm import tqdm

num_points = 1_000_000

def lfsr(seed):
    val = []
    for i in range(48):
        val.append(seed % 2)
        seed //= 2
    
    while True:
        newval = val.copy()
        newval.pop(47)
        newval.insert(0, 0)
        newval[0]     = val[47]
        newval[1]     = val[0]  ^ val[47]
        newval[26]    = val[25] ^ val[47]
        newval[27]    = val[26] ^ val[47]
        val = newval
        yield val

def arr_to_num(arr):
    output = 0
    for d in arr:
        output *= 2
        output += d
    return output

points = np.zeros((num_points, 3))
random.seed("prng")
lfsr_rng = lfsr(0x123456789abc)
for i in tqdm(range(num_points)):
    rand_num = next(lfsr_rng)
    point = (
        arr_to_num(rand_num[:16]) / (2**16) - 0.5, 
        arr_to_num(rand_num[16:32]) / (2**16) - 0.5, 
        arr_to_num(rand_num[32:]) / (2**16) - 0.5)
    np_point = np.array(point)
    np_point /= np.linalg.norm(np_point)
    points[i] = np_point

fig = plt.figure(figsize=(12, 12))
ax = fig.add_subplot(projection='3d')
ax.set_aspect('equal')

x_data, y_data, z_data = zip(*points)
# print(points)
# print(x_data)
# print(y_data)
# print(z_data)

ax.scatter(x_data, y_data, z_data, s=0.5, alpha=0.1, marker='.')
plt.show()