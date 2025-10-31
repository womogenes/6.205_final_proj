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

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24

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

    x = 2.14159
    y = 3.14159

    x_f = make_fp24(x)
    y_f = make_fp24(y)

    dut.a.value = x_f
    dut.b.value = y_f
    dut.is_sub.value = 0
    await ClockCycles(dut.clk, 3)

    s = dut.sum.value
    
    dut._log.info(f"{s.integer:#6x}")
    dut._log.info(f"{convert_fp24(s)}")
    dut._log.info(f"{x+y=}")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "multiplier.sv",
        proj_path / "hdl" / "math" / "fp24_add.sv"
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "fp24_add"
    
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
