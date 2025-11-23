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
import glob
from argparse import ArgumentParser

from PIL import Image
from tqdm import tqdm

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24, convert_fp24_vec3, pack_bits, make_fp24_vec3

parser = ArgumentParser()
parser.add_argument("--scale", type=float, default=0.5)
args = parser.parse_args()

if "SCALE" in os.environ:
    scale = float(os.environ["SCALE"])
else:
    scale = args.scale
    os.environ["SCALE"] = str(scale)

WIDTH = int(32 * scale)
HEIGHT = int(18 * scale)

proj_path = Path(__file__).resolve().parent.parent.parent
SCENE_BUF_MEM_PATH = str(proj_path / "data" / "scene_buffer.mem")

with open(SCENE_BUF_MEM_PATH, "r") as fin:
    NUM_OBJS = fin.read().strip().count("\n") + 1

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lazy mult module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1

    dut.cam.value = pack_bits([
        (make_fp24_vec3((0, 0, 0)), 72),            # origin
        (make_fp24_vec3((0, 0, WIDTH / 2)), 72),    # forward
        (make_fp24_vec3((1, 0, 0)), 72),            # right
        (make_fp24_vec3((0, 1, 0)), 72),            # up
    ])
    dut.num_objs.value = NUM_OBJS

    await ClockCycles(dut.clk, 100)
    dut.rst.value = 0

    img = Image.new("RGB", (WIDTH, HEIGHT))

    def unpack_color8(color8):
        return (
            ((color8 >> 0) & 0b11111) << 3,
            ((color8 >> 5) & 0b111111) << 2,
            ((color8 >> 11) & 0b11111) << 3
        )

    dut._log.info(f"{WIDTH=}, {HEIGHT=}")
    dut._log.info(f"{scale=}")

    for _ in tqdm(range(WIDTH * HEIGHT), ncols=80, gui=False):
    # for _ in range(WIDTH * HEIGHT):
        await RisingEdge(dut.ray_done)

        pixel_h = dut.pixel_h.value.integer
        pixel_v = dut.pixel_v.value.integer
        pixel_color = unpack_color8(dut.rtx_pixel.value.integer)

        # dut._log.info(pixel_color)

        r, g, b = pixel_color

        # dut._log.info(f"{pixel_h=}, {pixel_v=}, {pixel_color=}")
        img.putpixel((pixel_h, pixel_v), (r, g, b))

    img.save("test.png")


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "pipeline.sv",
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        *glob.glob(f"{proj_path}/hdl/math/*.sv", recursive=True),
        *glob.glob(f"{proj_path}/hdl/rng/*.sv", recursive=True),
        proj_path / "hdl" / "rtx" / "ray_signal_gen.sv",
        proj_path / "hdl" / "rtx" / "ray_maker.sv",
        proj_path / "hdl" / "rtx" / "ray_caster.sv",

        proj_path / "hdl" / "mem" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
        proj_path / "hdl" / "rtx" / "scene_buffer.sv",

        proj_path / "hdl" / "rtx" / "ray_intersector.sv",
        proj_path / "hdl" / "rtx" / "ray_reflector.sv",
        proj_path / "hdl" / "rtx" / "ray_tracer.sv",
        proj_path / "hdl" / "rtx" / "rtx.sv",
        proj_path / "hdl" / "rtx" / "rtx_tb.sv",
    ]
    build_test_args = ["-Wall"]

    build_dir = proj_path / "sim" / "sim_build"
    shutil.copy(SCENE_BUF_MEM_PATH, build_dir / "scene_buffer.mem")

    # values for parameters defined earlier in the code.
    parameters = {
        "WIDTH": WIDTH,
        "HEIGHT": HEIGHT,
    }

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "rtx_tb"
    
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
