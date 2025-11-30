# Find evil bithack constants, among others

import math
from functools import lru_cache
import numpy as np
from tqdm import tqdm

import sys
from pathlib import Path

proj_path = Path(__file__).parent.parent
sys.path.append(str(proj_path / "sim"))
from utils import make_fp, convert_fp, FP_BITS, FP_EXP_BITS

# Helper function for searching the whole space
def window_search(x: int, cost_fun, win_size: int, n_samples: int):
    """
    Centered at x, sample `cost` along `samples` points within the window
        [x - win_size / 2, x + win_size / 2].
    Recursively halve window size until win_size < 1.
    """
    if win_size < 1:
        return x, cost_fun(x)

    print(f"Running window search centered on {x}, {win_size=}, {n_samples=}")

    x_lo = math.floor(x - win_size / 2)
    x_hi = math.ceil(x + win_size / 2)

    x_sample_spacing = max(1, (x_hi - x_lo) // n_samples)
    x_sampled = sorted(set(range(x_lo, x_hi + 1, x_sample_spacing)))
    cost_sampled = [cost_fun(x) for x in x_sampled]

    # import matplotlib.pyplot as plt
    # plt.plot(x_sampled, np.minimum(cost_sampled, 10))
    # plt.xlabel("x sampled")
    # plt.ylabel("cost")
    # plt.show()

    # Find x that minimizes cost samp
    best_x_idx = 0
    for i in range(len(x_sampled)):
        if cost_sampled[i] < cost_sampled[best_x_idx]:
            best_x_idx = i
    
    return window_search(
        x=x_sampled[best_x_idx],
        cost_fun=cost_fun,
        win_size=(win_size / 2),
        n_samples=n_samples
    )


# Evil bithack constant for inverse square root
@lru_cache(None)
def cost_inv_sqrt_const(magic_const: int):
    """
    Calculate mean relative error for x across a spectrum
    """
    assert isinstance(magic_const, int)

    a_vals = np.exp2(np.linspace(-16, 16, 1_000))
    init_guesses = np.zeros_like(a_vals)

    for i, a in enumerate(a_vals):
        a_fp = make_fp(float(a))
        init_guesses[i] = convert_fp(magic_const - (a_fp >> 1))

    best_guesses = 1 / np.sqrt(a_vals)
    return np.mean(np.abs(best_guesses / init_guesses - 1))

# Evil bithack constant for inverse
@lru_cache(None)
def cost_inv_const(magic_const: int):
    """
    Calculate mean relative error for x across a spectrum
    """
    assert isinstance(magic_const, int)

    a_vals = np.exp2(np.linspace(-16, 16, 1_000))
    init_guesses = np.zeros_like(a_vals)

    for i, a in enumerate(a_vals):
        a_fp = make_fp(float(a))
        init_guesses[i] = convert_fp(magic_const - a_fp)

    best_guesses = 1 / a_vals
    return np.mean(np.abs(best_guesses / init_guesses - 1))


if __name__ == "__main__":
    inv_sqrt_magic_num, inv_sqrt_cost = window_search(
        (1 << FP_BITS) / 2, cost_inv_sqrt_const, 1 << FP_BITS, 100)
    inv_magic_num, inv_cost = window_search(
        (1 << FP_BITS) / 2, cost_inv_const, 1 << FP_BITS, 100)
    
    print(f"""\n===== PASTE INTO CONSTANTS.SV =====\n
parameter fp FP_HALF_SCREEN_WIDTH = 'h{make_fp(1280 // 2):x};
parameter fp FP_ONE = 'h{make_fp(1):x};
parameter fp FP_THREE = 'h{make_fp(3):x};
parameter fp FP_TWO = 'h{make_fp(2):x};
parameter fp FP_INV_SQRT_MAGIC_NUM = 'h{inv_sqrt_magic_num:x}; // ({inv_sqrt_cost * 100:.4f}% error)
parameter fp FP_INV_MAGIC_NUM = 'h{inv_magic_num:x}; // ({inv_cost * 100:.4f}% error)

=====================
""")
