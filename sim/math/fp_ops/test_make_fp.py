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

sys.path.append((Path(__file__).resolve().parent.parent.parent)._str)
from utils import convert_fp, make_fp

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
    
    N_TESTS = 1000

    for _ in range(N_TESTS):
        n_bin = np.random.randint(0, 2**32)
        dut.n.value = n_bin

        await ClockCycles(dut.clk, 2)
        dut_ans = convert_fp(dut.x.value)
        exp_ans = ctypes.c_int32(n_bin).value

        assert abs(dut_ans / exp_ans - 1) < 0.01, f"Expected {exp_ans}, got {dut_ans}"

        dut._log.info(f"{dut_ans=}, {exp_ans=}")

    dut._log.info(f"")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "clz.sv",
        proj_path / "hdl" / "math" / "fp_convert.sv"
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {"WIDTH": 32}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "make_fp"
    
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
