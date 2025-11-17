import os
import sys
import glob

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from enum import Enum
import random
import ctypes
import numpy as np
import matplotlib.pyplot as plt

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24_vec3, convert_fp24

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lfsr prng sphere module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    dut.seed.value = 0x123456789abc
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 20)
    num_points = 10_000
    points = []
    for i in range(num_points):
        points.append(convert_fp24_vec3(dut.rng_vec.value))
        await ClockCycles(dut.clk, 1)

    x_data, y_data, z_data = zip(*points)

    # Print statistics
    dut._log.info(f"\nGenerated {num_points} random vectors:")
    dut._log.info(f"  X range: [{min(x_data):.3f}, {max(x_data):.3f}]")
    dut._log.info(f"  Y range: [{min(y_data):.3f}, {max(y_data):.3f}]")
    dut._log.info(f"  Z range: [{min(z_data):.3f}, {max(z_data):.3f}]")
    dut._log.info(f"  X avg: {sum(x_data)/len(x_data):.3f}")
    dut._log.info(f"  Y avg: {sum(y_data)/len(y_data):.3f}")
    dut._log.info(f"  Z avg: {sum(z_data)/len(z_data):.3f}")

    # Check if all positive (which would be wrong)
    all_x_positive = all(x >= 0 for x in x_data)
    all_y_positive = all(y >= 0 for y in y_data)
    all_z_positive = all(z >= 0 for z in z_data)

    if all_x_positive and all_y_positive and all_z_positive:
        dut._log.error("  BUG: All vectors are in the positive octant!")
    else:
        dut._log.info("  OK: Vectors span negative and positive regions")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types"/ "types.sv",
        proj_path / "hdl" / "pipeline.sv",
        *glob.glob(f'{proj_path}/hdl/math/*.sv', recursive=True),
        *glob.glob(f'{proj_path}/hdl/rng/*.sv', recursive=True),
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "prng_sphere_lfsr"
    
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
        build_dir=(proj_path / "sim" / "sim_build")
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=test_file,
        test_args=run_test_args,
        waves=True,
    )


if __name__ == "__main__":
    runner()
