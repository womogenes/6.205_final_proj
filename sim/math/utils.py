# Convert bit representations

import ctypes

import cocotb
from cocotb.binary import BinaryValue

# We LOVE global variables
FULL_WIDTH = 32
FRAC_WIDTH = 16

assert FRAC_WIDTH <= FULL_WIDTH, "More fractional bits than full bits"

def fixed2float(fixed: BinaryValue):
    """
    Convert fixed-point binary string to Python float
    """
    assert FULL_WIDTH == 32, "Only 32-bit full widths are supported in testbench"
    return float(ctypes.c_int32(fixed).value) / (1 << FRAC_WIDTH)

def float2fixed(x: float):
    """
    Convert Python float to fixed-point representation
    """
    return int(x * (1 << FRAC_WIDTH)) & ((1 << FULL_WIDTH) - 1)

def make_vec3(vec3: tuple[float]):
    """
    Convert (x, y, z) to packed 96*-bit vec3
        * assuming FULL_WIDTH == 32
    """
    x, y, z = vec3
    return (
        (float2fixed(x) << (FULL_WIDTH * 2)) +
        (float2fixed(y) << (FULL_WIDTH * 1)) +
        (float2fixed(z) << (FULL_WIDTH * 0))
    )

def convert_vec3(vec3: BinaryValue):
    """
    Unpack 96-bit vec3 into tuple of 3 floats
    """
    mask = (1 << FULL_WIDTH) - 1
    x = fixed2float((vec3 >> (FULL_WIDTH * 2)) & mask)
    y = fixed2float((vec3 >> (FULL_WIDTH * 1)) & mask)
    z = fixed2float((vec3 >> (FULL_WIDTH * 0)) & mask)
    return (x, y, z)
