import os
import sys

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from enum import Enum
import random
import ctypes
import numpy as np

sys.path.append(Path(__file__).resolve().parent.parent.parent.parent._str)
from sim.utils import *

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lazy mult module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    async def do_test(a: tuple[float], b: tuple[float]):
        """
        a is a length-3 iterable of floats
        b is a scalar
        Pass this to the mul_vec3f module
        """
        dut.w.value = make_fp24_vec3(a)
        dut.v.value = make_fp24_vec3(b)

        # 1 cycle to feed input, 1 cycle to calculate
        await ClockCycles(dut.clk, 4)

        cross = convert_fp24_vec3(dut.cross_prod.value)
        return cross

    total_sq_error = 0
    n_tests = 100

    for _ in range(n_tests):
        a = (np.random.rand(3) - 0.5) * 100
        b = (np.random.rand(3) - 0.5) * 100
        cross = await do_test(a.tolist(), b.tolist())
        print(f"{a=}, {b=}, ans={np.cross(a, b)}, {cross=}")

        # Compute error
        total_sq_error += np.square(np.linalg.norm(np.cross(a, b) - cross))

    # Print max error
    # Expect around 1e-06 for 16.16 fixeds
    dut._log.info(f"Mean error: {np.mean(total_sq_error) / n_tests}")

    await ClockCycles(dut.clk, 5)


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "types"/ "types.sv",
        proj_path / "hdl" / "math" / "clz.sv",
        proj_path / "hdl" / "math"/ "fp24_add.sv",
        proj_path / "hdl" / "math"/ "fp24_mul.sv",
        proj_path / "hdl" / "math" / "fp24_vec3_ops.sv"
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "fp24_vec3_cross"
    
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
