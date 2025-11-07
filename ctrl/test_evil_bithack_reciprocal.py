import numpy as np
import sys
from pathlib import Path

import matplotlib.pyplot as plt

sys.path.append(str(Path(__file__).parent.parent / "sim"))
from utils import make_fp24, convert_fp24

from tqdm import tqdm

def init_guess_inv(x: float, magic_const: int):
    """
    Return initial guess for 1/x using evil bithack
    """
    f = make_fp24(x)
    
    # sign = f & (1 << 23)
    # exp = (f >> 16) & 0x7F
    # mant = f & 0xFFFF

    # f_inv = sign + (((125 - exp) & 0x7F) << 16) + ((magic_const - ((mant >> 0) & 0xFFFF)) & 0xFFFF)

    f_inv = (f & (1 << 23)) + (((magic_const & 0x7FFFFF) - f) & 0x7FFFFF)
    return convert_fp24(f_inv)


if __name__ == "__main__":
    x = np.concat([
        -np.power(2, np.linspace(16, -16, 1_000)),
        np.power(2, np.linspace(-16, 16, 1_000)),
    ])

    def get_score(magic_const):
        x_inv = np.array([init_guess_inv(a, magic_const) for a in x])
        mean_rel_err = np.mean(abs((1/x) / x_inv - 1))

        return mean_rel_err

    magic_consts, scores = [], []
    for magic_const in tqdm(np.linspace(8.2485e6, 8.2495e6, 1_000), ncols=80):
        magic_const = int(magic_const)
        magic_consts.append(magic_const)
        scores.append(min(10, get_score(magic_const)))

    best_const_idx = np.argmin(scores)
    best_const = magic_consts[best_const_idx]
    best_score = scores[best_const_idx]
    print(f"Best constant: {best_const} (0x{best_const:06x}) ({best_score * 100:.6f}%)")

    plt.plot(magic_consts, scores)
    plt.xlabel("magic constant")
    plt.ylabel("mean relative error in 1/x initial guess")
    plt.yscale("log")
    plt.show()
