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

from PIL import Image
from tqdm import tqdm

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24, convert_fp24_vec3, make_fp24_vec3

WIDTH = 32 * 1
HEIGHT = 18 * 1

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lazy mult module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0

    # DELAY_CYCLES = 29

    N_SAMPLES = 1

    dut.ray_origin.value = make_fp24_vec3((0, 0, 0))
    dut.ray_dir.value = make_fp24_vec3((0, 0, 1))
    dut.sphere_center.value = make_fp24_vec3((0, 0, 5))
    dut.sphere_rad_sq.value = make_fp24(1)
    dut.sphere_rad_inv.value = make_fp24(1)

    dut.sphere_valid.value = 1
    await ClockCycles(dut.clk, 1)
    dut.sphere_valid.value = 0

    await ClockCycles(dut.clk, 100)

    # Extract answer
    hit = dut.hit.value
    hit_pos = convert_fp24_vec3(dut.hit_pos.value)
    hit_dist_sq = convert_fp24(dut.hit_dist_sq.value)
    hit_norm = convert_fp24_vec3(dut.hit_norm.value)

    dut._log.info(f"""
{hit=}
{hit_pos=}
{hit_dist_sq=}
{hit_norm=}
""")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "pipeline.sv",
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "clz.sv",
        proj_path / "hdl" / "math" / "fp24_shift.sv",
        proj_path / "hdl" / "math" / "fp24_add.sv",
        proj_path / "hdl" / "math" / "fp24_mul.sv",
        proj_path / "hdl" / "math" / "fp24_inv_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_vec3_ops.sv",
        proj_path / "hdl" / "math" / "sphere_intersector.sv",
        proj_path / "hdl" / "rtx" / "quadratic_solver.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "sphere_intersector"
    
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
