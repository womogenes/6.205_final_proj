"""
test_rtx_parallel.py

Takes advantage of multithreading to render testbench images much faster
"""

import warnings
warnings.filterwarnings("ignore", category=UserWarning)

import os
import sys
import shutil
from pathlib import Path
from argparse import ArgumentParser, BooleanOptionalAction

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.runner import get_runner

import numpy as np
import time

from PIL import Image
from tqdm import tqdm

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import make_fp_vec3, pack_bits

# MULTIPROCESSING GO BRRR
from multiprocessing import Pool

parser = ArgumentParser()
parser.add_argument("--chunks", type=int, default=None)
parser.add_argument("--scale", type=float, default=0.5)
parser.add_argument("--frames", type=int, default=1)
parser.add_argument("--waves", action=BooleanOptionalAction)

args = parser.parse_args()
print(args)

FP_BITS = 24
FP_VEC3_BITS = FP_BITS * 3

# Use environment variables for worker processes
if "TEST_WIDTH" in os.environ:
    WIDTH = int(os.environ["TEST_WIDTH"])
    HEIGHT = int(os.environ["TEST_HEIGHT"])
    N_FRAMES = int(os.environ["TEST_N_FRAMES"])
    scale = WIDTH / 32
else:
    scale = args.scale
    WIDTH = int(32 * scale)
    HEIGHT = int(18 * scale)
    N_FRAMES = args.frames

N_CHUNKS = args.chunks or (4 * os.cpu_count() * N_FRAMES)
TOTAL_PIXELS = WIDTH * HEIGHT

# Round up on chunk size
CHUNK_SIZE = (TOTAL_PIXELS + N_CHUNKS - 1) // N_CHUNKS
CHUNK_RANGES = [
    (i * CHUNK_SIZE, min((i + 1) * CHUNK_SIZE - 1, TOTAL_PIXELS - 1))
    for i in range((TOTAL_PIXELS + CHUNK_SIZE - 1) // CHUNK_SIZE)
]
NUM_CHUNKS_ACTUAL = len(CHUNK_RANGES)

test_file = os.path.basename(__file__).replace(".py", "")

proj_path = Path(__file__).resolve().parent.parent.parent
SCENE_BUF_MEM_PATH = str(proj_path / "data" / "scene_buffer.mem")

with open(SCENE_BUF_MEM_PATH, "r") as fin:
    NUM_OBJS = fin.read().strip().count("\n") + 1

# Location to store chunk .npy files
CHUNKS_OUT_DIR = proj_path / "sim" / "sim_build" / "rtx_parallel" / "chunks"
os.makedirs(CHUNKS_OUT_DIR, exist_ok=True)

# Single shared build directory for all workers
BUILD_DIR = proj_path / "sim" / "sim_build" / "rtx_parallel" / f"verilator_{WIDTH}x{HEIGHT}"
os.makedirs(BUILD_DIR, exist_ok=True)

# Common configuration for Verilator build and test
SIM = os.getenv("SIM", "verilator")
HDL_TOPLEVEL = "rtx_tb_parallel"

sys.path.append(str(proj_path / "sim"))

SOURCES = [
    proj_path / "hdl" / "pipeline.sv",
    proj_path / "hdl" / "constants.sv",
    proj_path / "hdl" / "types" / "types.sv",
    proj_path / "hdl" / "math" / "clz.sv",
    proj_path / "hdl" / "math" / "fp_shift.sv",
    proj_path / "hdl" / "math" / "fp_add.sv",
    proj_path / "hdl" / "math" / "fp_clip.sv",
    proj_path / "hdl" / "math" / "fp_mul.sv",
    proj_path / "hdl" / "math" / "fp_inv_sqrt.sv",
    proj_path / "hdl" / "math" / "fp_sqrt.sv",
    proj_path / "hdl" / "math" / "fp_vec3_ops.sv",
    proj_path / "hdl" / "math" / "fp_convert.sv",
    proj_path / "hdl" / "math" / "specular_reflect.sv",
    proj_path / "hdl" / "rng" / "prng_sphere.sv",
    proj_path / "hdl" / "rng" / "prng8.sv",
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

BUILD_TEST_ARGS = [
    "-Wno-WIDTHEXPAND",
    "-Wno-MULTIDRIVEN",
    "-Wno-WIDTHTRUNC",
    "-Wno-TIMESCALEMOD",
    "-Wno-PINMISSING",
    "-Wno-BLKSEQ",
]

PARAMETERS = {
    "WIDTH": WIDTH,
    "HEIGHT": HEIGHT,
}


@cocotb.test()
async def test_module(dut):
    # dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # dut._log.info("Holding reset...")
    dut.lfsr_seed.value = int.from_bytes(os.urandom(12))
    dut.rst.value = 1

    dut.cam.value = pack_bits([
        (make_fp_vec3((0, 0, -10)), FP_VEC3_BITS),            # origin
        (make_fp_vec3((0, 0, WIDTH / 2 * 2.28)), FP_VEC3_BITS),    # forward
        (make_fp_vec3((1, 0, 0)), FP_VEC3_BITS),            # right
        (make_fp_vec3((0, 1, 0)), FP_VEC3_BITS),            # up
    ])
    dut.num_objs.value = NUM_OBJS
    dut.max_bounces.value = 3

    await ClockCycles(dut.clk, 100)
    dut.rst.value = 0

    def unpack_color8(color8):
        return (
            ((color8 >> 0) & 0b11111) << 3,
            ((color8 >> 5) & 0b111111) << 2,
            ((color8 >> 11) & 0b11111) << 3
        )

    # Extract pixel_start_idx and pixel_end_idx from environment vars
    pixel_start_idx = int(os.environ["PIXEL_START_IDX"])
    pixel_end_idx = int(os.environ["PIXEL_END_IDX"])
    chunk_idx = int(os.environ.get("CHUNK_IDX", "0"))

    n_pixels = pixel_end_idx - pixel_start_idx + 1
    pixel_values = np.zeros((n_pixels, 3))

    for i in tqdm(range(N_FRAMES * n_pixels), ncols=120, desc=f"[chunk {chunk_idx:>3}/{NUM_CHUNKS_ACTUAL:<3}]"):
        pixel_idx = (i % n_pixels) + pixel_start_idx
        pixel_v_in = pixel_idx // WIDTH
        pixel_h_in = pixel_idx % WIDTH

        dut.pixel_h_in.value = pixel_h_in
        dut.pixel_v_in.value = pixel_v_in
        dut.new_ray.value = 1
        await ClockCycles(dut.clk, 1)
        dut.new_ray.value = 0

        await RisingEdge(dut.ray_done)
        # await ClockCycles(dut.clk, 1000)

        pixel_color = unpack_color8(dut.rtx_pixel.value.integer)

        r, g, b = pixel_color
        pixel_values[pixel_idx - pixel_start_idx] += (r, g, b)

    # Save into common chunks directory
    save_path = CHUNKS_OUT_DIR / f"chunk_{chunk_idx:04}.npy"
    np.save(save_path, np.floor(pixel_values / N_FRAMES))
    dut._log.info(f"Saved pixel chunk to {save_path}")


def build_verilator():
    """Build Verilator executable once (called from main process)."""
    print(f"Building Verilator for {WIDTH}x{HEIGHT}...")

    # Copy scene buffer to build dir
    shutil.copy(SCENE_BUF_MEM_PATH, BUILD_DIR / "scene_buffer.mem")

    runner = get_runner(SIM)
    runner.build(
        sources=SOURCES,
        hdl_toplevel=HDL_TOPLEVEL,
        always=False,  # skip if already built
        build_args=BUILD_TEST_ARGS,
        parameters=PARAMETERS,
        timescale=("1ns", "1ps"),
        waves=args.waves,
        build_dir=BUILD_DIR,
    )

    print(f"Build complete. Executable cached in {BUILD_DIR}")


def run_test_worker(pixel_start_idx: int, pixel_end_idx: int, chunk_idx: int):
    """Run test for a specific pixel chunk (called from worker process)."""

    # Set environment variables for this chunk
    os.environ["PIXEL_START_IDX"] = str(pixel_start_idx)
    os.environ["PIXEL_END_IDX"] = str(pixel_end_idx)
    os.environ["CHUNK_IDX"] = str(chunk_idx)

    # Set test parameters so workers use correct WIDTH/HEIGHT
    os.environ["TEST_WIDTH"] = str(WIDTH)
    os.environ["TEST_HEIGHT"] = str(HEIGHT)
    os.environ["TEST_N_FRAMES"] = str(N_FRAMES)

    # Get runner and initialize (build will be skipped since already built)
    runner = get_runner(SIM)
    runner.build(
        sources=SOURCES,
        hdl_toplevel=HDL_TOPLEVEL,
        always=False,
        build_args=BUILD_TEST_ARGS,
        parameters=PARAMETERS,
        timescale=("1ns", "1ps"),
        waves=args.waves,
        build_dir=BUILD_DIR,
    )

    # Now run test
    runner.test(
        hdl_toplevel=HDL_TOPLEVEL,
        test_module=test_file,
        test_args=[],
        waves=args.waves,
    )

    return chunk_idx


def worker(task):
    """Wrapper for Pool.map"""
    chunk_idx, start_idx, end_idx = task
    return run_test_worker(start_idx, end_idx, chunk_idx)


if __name__ == "__main__":
    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Frames: {N_FRAMES}")
    print(f"Chunks: {NUM_CHUNKS_ACTUAL}")
    print(f"Worker processes: {os.cpu_count()}")
    print()

    # Build Verilator once
    build_start = time.time()
    build_verilator()
    build_time = time.time() - build_start
    print(f"Build time: {build_time:.1f}s\n")

    # Create tasks for parallel execution
    tasks = [(chunk_idx, start_idx, end_idx)
             for chunk_idx, (start_idx, end_idx) in enumerate(CHUNK_RANGES)]

    # Run tests in parallel
    print("Starting parallel render...")
    render_start = time.time()
    with Pool(processes=os.cpu_count()) as pool:
        results = pool.map(worker, tasks)
    render_time = time.time() - render_start

    # Gather chunks and combine
    print("\nCombining chunks...")
    pixel_chunks = []
    for chunk_idx in range(len(CHUNK_RANGES)):
        chunk_path = CHUNKS_OUT_DIR / f"chunk_{chunk_idx:04}.npy"
        if not chunk_path.exists():
            raise FileNotFoundError(f"Expected chunk file missing: {chunk_path}")
        pixel_chunks.append(np.load(chunk_path))

    pixels_all = np.concatenate(pixel_chunks)
    img = Image.fromarray(pixels_all.reshape((HEIGHT, WIDTH, 3)).astype("uint8"))
    output_file = f"test_rtx_{WIDTH}x{HEIGHT}_f{N_FRAMES}.png"
    img.save(output_file)

    total_time = time.time() - build_start
    print(f"\n=== Render complete ===")
    print(f"Output: {output_file}")
    print(f"Build time: {build_time:.1f}s")
    print(f"Render time: {render_time:.1f}s ({render_time/60:.1f} min)")
    print(f"Total time: {total_time:.1f}s ({total_time/60:.1f} min)")
