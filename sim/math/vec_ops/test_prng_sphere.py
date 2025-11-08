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

sys.path.append(Path(__file__).resolve().parent.parent.parent.parent._str)
from sim.utils import convert_fp24_vec3, convert_fp24

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

    fig = plt.figure(figsize=(12, 12))
    ax = fig.add_subplot(projection='3d')
    ax.set_aspect('equal')

    x_data, y_data, z_data = zip(*points)

    ax.scatter(x_data, y_data, z_data, s=0.5, alpha=1, marker='.')
    plt.show()


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "types"/ "types.sv",
        proj_path / "hdl" / "pipeline.sv"
    ]
    verilog_files = glob.glob(f'{proj_path}/hdl/math/*.sv', recursive=True)
    sources.extend(verilog_files)
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
