import numpy as np
import sys
from pathlib import Path

import matplotlib.pyplot as plt

sys.path.append(str(Path(__file__).parent.parent / "sim"))
from utils import make_fp24, convert_fp24

def init_guess_inv(x: float):
    """
    Return initial guess for 1/x using evil bithack
    """
    f = make_fp24(x)
    
    sign = f & (1 << 23)
    exp = (f >> 16) & 0x7F
    mant = f & 0xFFFF

    f_inv = sign + (((126 - exp) & 0x7F) << 16) + (~mant)
    return convert_fp24(f_inv)


if __name__ == "__main__":
    x = np.linspace(0.001, 10, 100)
    x_inv = [init_guess_inv(a) for a in x]

    plt.plot(x, x_inv, label="Initial guess")
    plt.plot(x, 1/x, label="True value")
    plt.xscale("log")
    plt.yscale("log")
    plt.legend()
    plt.xlabel("x")
    plt.ylabel("1/x guess and true value")
    plt.show()
