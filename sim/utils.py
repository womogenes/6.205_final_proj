# Convert bit representations

import math
import ctypes

import cocotb
from cocotb.binary import BinaryValue

FP24_WIDTH = 24

# ===== FP24 REPRESENTATIONS =====
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

def convert_fp24(f: BinaryValue):
    """
    Convert 24-bit fp24 value to Python float
    """
    if isinstance(f, BinaryValue) and not f.is_resolvable:
        # Not a valid float
        return None
        
    # If all but the sign bit is zero, this represents zero
    if f & 0x7FFFFF == 0:
        return 0
    
    sign = -1 if (f >> 23) & 1 else 1
    exp = ((f >> 16) & 0x7F) - 63
    mant = 1 + (f & 0xFFFF) / (1 << 16)

    return sign * (2 ** exp) * mant

def make_fp24_vec3(vec3: tuple[float]):
    """
    Convert (x, y, z) to packed 72-bit fp24_vec3
    """
    x, y, z = vec3
    return (
        (make_fp24(x) << (FP24_WIDTH * 2)) +
        (make_fp24(y) << (FP24_WIDTH * 1)) +
        (make_fp24(z) << (FP24_WIDTH * 0))
    )

def convert_fp24_vec3(vec3: BinaryValue):
    """
    Unpack 72-bit vec3 into tuple of 3 floats
    """
    if isinstance(vec3, BinaryValue) and not vec3.is_resolvable:
        return (None, None, None)

    mask = (1 << FP24_WIDTH) - 1
    x = convert_fp24((vec3 >> (FP24_WIDTH * 2)) & mask)
    y = convert_fp24((vec3 >> (FP24_WIDTH * 1)) & mask)
    z = convert_fp24((vec3 >> (FP24_WIDTH * 0)) & mask)
    return (x, y, z)
