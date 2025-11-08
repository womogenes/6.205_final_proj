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
from utils import convert_fp24, make_fp24, convert_fp24_vec3, make_fp24_vec3

sys.path.append(str(Path(__file__).resolve().parent.parent.parent / "ctrl"))
from make_scene_buffer import Material, Object

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
    await ClockCycles(dut.clk, 60)
    dut.rst.value = 0

    # Fake object
    mat0 = Material(
        color=(1, 1, 1),
        spec_color=(1, 1, 1),
        emit_color=(1, 1, 1),
        smooth=1,
        specular=0,
    )
    objs = [
        Object(
            is_trig=False,
            mat=mat0,
            trig=None,
            trig_norm=None,
            sphere_center=(2, 0, 5),
            sphere_rad=2.01,
        ),
        Object(
            is_trig=False,
            mat=mat0,
            trig=None,
            trig_norm=None,
            sphere_center=(2, 0, 4),
            sphere_rad=2.01,
        ),
    ]
    
    dut.ray_origin.value = make_fp24_vec3((0, 0, 0))
    dut.ray_dir.value = make_fp24_vec3((0, 0, 1))

    # Manual timing
    await ClockCycles(dut.clk, 3)
    dut.obj.value = objs[0].pack_bits()[0]
    await ClockCycles(dut.clk, 1)
    dut.obj.value = objs[1].pack_bits()[0]
    dut.obj_last.value = 1

    for _ in range(50):
        await ClockCycles(dut.clk, 1)

    return

    img = Image.new("RGB", (WIDTH, HEIGHT))

    def unpack_color8(color8):
        return (
            ((color8 >> 0) & 0b11111) << 3,
            ((color8 >> 5) & 0b111111) << 2,
            ((color8 >> 11) & 0b11111) << 3
        )

    for _ in tqdm(range(WIDTH * HEIGHT), ncols=80, gui=False):
    # for _ in range(WIDTH * HEIGHT):
        # await RisingEdge(dut.ray_done)
        await ClockCycles(dut.clk, 100)

        pixel_h = dut.pixel_h.value.integer
        pixel_v = dut.pixel_v.value.integer
        pixel_color = unpack_color8(dut.rtx_pixel.value.integer)

        r, g, b = pixel_color

        # dut._log.info(f"{pixel_h=}, {pixel_v=}, {pixel_color=}")
        img.putpixel((pixel_h, pixel_v), (r, g, b))

    img.save("test.png")


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
        proj_path / "hdl" / "math" / "fp24_convert.sv",
        proj_path / "hdl" / "rtx" / "ray_signal_gen.sv",
        proj_path / "hdl" / "rtx" / "ray_maker.sv",
        proj_path / "hdl" / "rtx" / "ray_caster.sv",
        proj_path / "hdl" / "rtx" / "quadratic_solver.sv",
        proj_path / "hdl" / "rtx" / "sphere_intersector.sv",
        proj_path / "hdl" / "rtx" / "ray_intersector.sv",
    ]
    build_test_args = ["-Wall"]

    build_dir = proj_path / "sim" / "sim_build"

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "ray_intersector"
    
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
