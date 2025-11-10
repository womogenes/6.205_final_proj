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
import time

from PIL import Image
from tqdm import tqdm

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24, convert_fp24_vec3, pack_bits, make_fp24_vec3

# MULTIPROCESSING GO BRRR
from multiprocessing import Process

N_CHUNKS = 16

scale = 4
WIDTH = int(32 * scale)
HEIGHT = int(18 * scale)

test_file = os.path.basename(__file__).replace(".py", "")

proj_path = Path(__file__).resolve().parent.parent.parent

def get_build_dir(start_idx, end_idx):
    build_dir = proj_path / "sim" / "sim_build" / "rtx_parallel" / f"pixel_chunk_{start_idx:04}_{end_idx:04}"
    os.makedirs(build_dir, exist_ok=True)

    return build_dir

@cocotb.test()
async def test_module(dut):

    """cocotb test for the lazy mult module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 100)
    dut.rst.value = 0

    dut.cam.value = pack_bits([
        (make_fp24_vec3((0, 0, 0)), 72),            # origin
        (make_fp24_vec3((0, 0, WIDTH / 2)), 72),    # forward
        (make_fp24_vec3((1, 0, 0)), 72),            # right
        (make_fp24_vec3((0, 1, 0)), 72),            # up
    ])

    def unpack_color8(color8):
        return (
            ((color8 >> 0) & 0b11111) << 3,
            ((color8 >> 5) & 0b111111) << 2,
            ((color8 >> 11) & 0b11111) << 3
        )

    # Extract pixel_start_idx and pixel_end_idx from environment vars
    pixel_start_idx = int(os.environ["PIXEL_START_IDX"])
    pixel_end_idx = int(os.environ["PIXEL_END_IDX"])
    pixel_values = []

    for pixel_idx in tqdm(range(pixel_start_idx, pixel_end_idx + 1), ncols=80):
    # for pixel_idx in range(pixel_start_idx, pixel_end_idx + 1):
        pixel_v_in = pixel_idx // WIDTH
        pixel_h_in = pixel_idx % WIDTH

        dut.pixel_h_in.value = pixel_h_in
        dut.pixel_v_in.value = pixel_v_in

        await RisingEdge(dut.ray_done)

        pixel_color = unpack_color8(dut.rtx_pixel.value.integer)

        r, g, b = pixel_color
        pixel_values.append((r, g, b))

    build_dir = get_build_dir(pixel_start_idx, pixel_end_idx)
    save_path = build_dir / "chunk.npy"
    np.save(save_path, pixel_values)
    dut._log.info(f"Saved pixel chunk to {save_path}")


def runner(pixel_start_idx: int, pixel_end_idx: int):
    """Module tester."""

    # Set pixel_start_idx and pixel_end_idx for multiprocessing
    os.environ["PIXEL_START_IDX"] = str(pixel_start_idx)
    os.environ["PIXEL_END_IDX"] = str(pixel_end_idx)

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    sources = [
        proj_path / "hdl" / "pipeline.sv",
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "clz.sv",
        proj_path / "hdl" / "math" / "fp24_shift.sv",
        proj_path / "hdl" / "math" / "fp24_add.sv",
        proj_path / "hdl" / "math" / "fp24_clip.sv",
        proj_path / "hdl" / "math" / "fp24_mul.sv",
        proj_path / "hdl" / "math" / "fp24_inv_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_vec3_ops.sv",
        proj_path / "hdl" / "math" / "fp24_convert.sv",
        proj_path / "hdl" / "rng" / "prng_sphere.sv",
        proj_path / "hdl" / "math" / "quadratic_solver.sv",
        proj_path / "hdl" / "math" / "sphere_intersector.sv",
        proj_path / "hdl" / "rtx" / "ray_signal_gen.sv",
        proj_path / "hdl" / "rtx" / "ray_maker.sv",
        proj_path / "hdl" / "rtx" / "ray_caster.sv",

        proj_path / "hdl" / "mem" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
        proj_path / "hdl" / "rtx" / "scene_buffer.sv",

        proj_path / "hdl" / "rtx" / "ray_intersector.sv",
        proj_path / "hdl" / "rtx" / "ray_reflector.sv",
        proj_path / "hdl" / "rtx" / "ray_tracer.sv",
        proj_path / "hdl" / "rtx" / "rtx.sv",
        proj_path / "hdl" / "rtx" / "rtx_tb_parallel.sv",
    ]
    build_test_args = ["-Wall"]

    build_dir = get_build_dir(pixel_start_idx, pixel_end_idx)

    shutil.copy(str(proj_path / "data" / "scene_buffer.mem"), build_dir / "scene_buffer.mem")

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
    total_pixels = WIDTH * HEIGHT
    chunk_size = total_pixels // N_CHUNKS
    
    procs = []
    chunk_ranges = []
    for chunk_idx in range(N_CHUNKS):
        start_idx = chunk_idx * chunk_size
        end_idx = (chunk_idx + 1) * chunk_size - 1
        chunk_ranges.append((start_idx, end_idx))

        p = Process(target=runner, args=(start_idx, end_idx))

        p.start()
        procs.append(p)

    for p in procs:
        p.join()

    pixel_chunks = []
    for start_idx, end_idx in chunk_ranges:
        build_dir = get_build_dir(start_idx, end_idx)
        pixel_chunks.append(np.load(build_dir / "chunk.npy"))

    pixels_all = np.concat(pixel_chunks)
    img = Image.fromarray(pixels_all.reshape((HEIGHT, WIDTH, 3)).astype("uint8"))
    img.save(f"test_frame_0.png")

    print(f"Saved image to test_frame_0.png")
