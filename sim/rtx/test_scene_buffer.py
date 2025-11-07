import os
import sys
import shutil

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
from utils import convert_fp24, make_fp24, convert_fp24_vec3

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
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    for i in range(2):
        dut.obj_idx.value = i
        await ClockCycles(dut.clk, 10)

        dut_sphere_rad_sq = convert_fp24(dut.sphere_rad_sq.value)
        dut_sphere_rad_inv = convert_fp24(dut.sphere_rad_inv.value)
        print("Sphere radius squared:", dut_sphere_rad_sq)
        print("Sphere radius inv:", dut_sphere_rad_inv)
        print(f"Sphere radius: {dut_sphere_rad_sq ** 0.5} ~ {1 / dut_sphere_rad_inv}")
        print("Sphere center:", convert_fp24_vec3(dut.sphere_center.value))


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl"/ "mem" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
        proj_path / "hdl" / "pipeline.sv",
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "rtx" / "scene_buffer.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {"INIT_FILE": '"scene_buffer.mem"'}

    # Copy scene buffer file
    build_dir = proj_path / "sim" / "sim_build"
    shutil.copy(str(proj_path / "data" / "scene_buffer.mem"), build_dir / "scene_buffer.mem")

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "scene_buffer"
    
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
        build_dir=build_dir,
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
