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

sys.path.append(Path(__file__).resolve().parent.parent.parent._str)
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

    async def do_test(x: float, y: float, is_sub: bool):
        """
        Do a single test on x + y using fp_24_add
        """
        x_f = make_fp24(x)
        y_f = make_fp24(y)

        dut.a.value = x_f
        dut.b.value = y_f
        dut.is_sub.value = is_sub
        await ClockCycles(dut.clk, 3)
        
        return convert_fp24(dut.sum.value)
    
    # x = -38000
    # y = 39000
    # res = await do_test(x, y, 0)
    # dut._log.info(f"{res=}, {x+y=}")
    # return
    
    n_tests = 1_000
    total_err = 0
    for _ in range(n_tests):
        x = (random.random() - 0.5) * 200
        y = (random.random() - 0.5) * 200
        is_sub = random.random() < 0.5
        
        exp_ans = x - y if is_sub else x + y
        dut_ans = await do_test(x, y, is_sub)

        dut._log.info(f"{x=:>10.3f} {y=:>10.3f} {is_sub=:>5} {exp_ans=:>10.3f} {dut_ans=:>10.3f} diff={exp_ans-dut_ans}")

        total_err += abs(exp_ans - dut_ans)

    dut._log.info(f"Mean error: {total_err / n_tests}")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "clz.sv",
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
