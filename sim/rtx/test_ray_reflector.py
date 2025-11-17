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

sys.path.append(Path(__file__).resolve().parent.parent.parent._str)
from sim.utils import convert_fp24_vec3, convert_fp24, make_fp24, make_fp24_vec3, make_material

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lfsr prng sphere module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    dut.lfsr_seed = 0x1234_5678_abcd
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 20)
    dut.hit_valid.value = 1

    dut.ray_dir.value = 0 #TODO change when specular implemented
    dut.ray_color.value = make_fp24_vec3((1.0, 0.5, 0.25))
    dut.income_light.value = make_fp24_vec3((1.0, 1.0, 1.0))

    dut.hit_pos.value = make_fp24_vec3((0, 0, 0))
    dut.hit_normal.value = make_fp24_vec3(((1/3)**0.5, (1/3)**0.5, (1/3)**0.5))
    # dut.hit_normal.value = make_fp24_vec3((0, 0, 1))

    mat = make_material(
        color=make_fp24_vec3((1.0, 0.5, 0.25)), 
        emit_color=make_fp24_vec3((0, 0, 0)),
        specular=255,
        smooth=make_fp24(1),
    )
    dut.hit_mat.value = mat

    await ClockCycles(dut.clk, 1)
    dut.hit_valid.value = 0

    num_points = 1
    points = []
    for i in range(num_points):
        # await RisingEdge(dut.reflect_done)
        await ClockCycles(dut.clk, 100)

        await ClockCycles(dut.clk, 1)
        points.append(convert_fp24_vec3(dut.new_dir.value))
        dut.hit_valid.value = 1
        await ClockCycles(dut.clk, 1)
        dut.hit_valid.value = 0

    print(convert_fp24_vec3(dut.new_income_light.value))
    # assert convert_fp24_vec3(dut.new_color.value) == (1, 1/4, 1/16)
    # assert convert_fp24_vec3(dut.new_income_light.value) == (1, 1, 1)


    fig = plt.figure(figsize=(12, 12))
    ax = fig.add_subplot(projection='3d')
    ax.set_aspect('equal')
    ax.set_xlim3d(-1, 1)
    ax.set_ylim3d(-1, 1)
    ax.set_zlim3d(-1, 1)

    x_data, y_data, z_data = zip(*points)

    ax.scatter(x_data, y_data, z_data, s=2, alpha=1, marker='.')
    plt.show()


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "pipeline.sv",
        *glob.glob(f'{proj_path}/hdl/rng/*.sv', recursive=True),
        *glob.glob(f'{proj_path}/hdl/math/*.sv', recursive=True),
        proj_path / "hdl" / "rtx" / "ray_reflector.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "ray_reflector"
    
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
