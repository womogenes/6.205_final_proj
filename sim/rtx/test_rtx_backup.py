import warnings
warnings.filterwarnings("ignore", category=UserWarning)

import os
import sys
import shutil
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.runner import get_runner

import numpy as np
import time

from PIL import Image
from tqdm import tqdm

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import make_fp24_vec3, pack_bits

# MULTIPROCESSING GO BRRR
from multiprocessing import Pool, Manager

N_CHUNKS = 4 * os.cpu_count()

scale = 10
WIDTH = int(32 * scale)
HEIGHT = int(18 * scale)
N_FRAMES = 8

TOTAL_PIXELS = WIDTH * HEIGHT

CHUNK_SIZE = (TOTAL_PIXELS + N_CHUNKS - 1) // N_CHUNKS  # ceil division
CHUNK_RANGES = [
    (i * CHUNK_SIZE, min((i + 1) * CHUNK_SIZE - 1, TOTAL_PIXELS - 1))
    for i in range((TOTAL_PIXELS + CHUNK_SIZE - 1) // CHUNK_SIZE)
]
NUM_CHUNKS_ACTUAL = len(CHUNK_RANGES)

test_file = os.path.basename(__file__).replace(".py", "")

proj_path = Path(__file__).resolve().parent.parent.parent

# Location to store chunk .npy files
CHUNKS_OUT_DIR = proj_path / "sim" / "sim_build" / "rtx_parallel" / "chunks"
os.makedirs(CHUNKS_OUT_DIR, exist_ok=True)

# Build directory
SHARED_BASE_DIR = proj_path / "sim" / "sim_build" / "rtx_parallel"
os.makedirs(SHARED_BASE_DIR, exist_ok=True)

def get_shared_build_dir(shared_idx: int):
    """Return the path to a shared build directory for index shared_idx."""
    build_dir = SHARED_BASE_DIR / f"shared_build_{shared_idx:03}"
    os.makedirs(build_dir, exist_ok=True)
    return build_dir


@cocotb.test()
async def test_module(dut):
    """Render chunk with frame averaging (saves each chunk to CHUNKS_OUT_DIR)."""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.lfsr_seed.value = int.from_bytes(os.urandom(6))
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

        pixel_color = unpack_color8(dut.rtx_pixel.value.integer)

        r, g, b = pixel_color
        pixel_values[pixel_idx - pixel_start_idx] += (r, g, b)

    # Save into common chunks directory
    save_path = CHUNKS_OUT_DIR / f"chunk_{chunk_idx:04}.npy"
    np.save(save_path, np.floor(pixel_values / N_FRAMES))
    dut._log.info(f"Saved pixel chunk to {save_path}")


def runner(
    pixel_start_idx: int,
    pixel_end_idx: int,
    chunk_idx: int,
    shared_idx: int,
    shared_lock
):
    """Module tester.

      - Acquire lock for shared build dir
      - Copy scene file into the shared build dir, call runner.build
      - Run test
    """

    # Set pixel_start_idx and pixel_end_idx for multiprocessing
    os.environ["PIXEL_START_IDX"] = str(pixel_start_idx)
    os.environ["PIXEL_END_IDX"] = str(pixel_end_idx)
    os.environ["CHUNK_IDX"] = str(chunk_idx)

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")

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

    build_test_args = ["-Wno-WIDTHEXPAND", "-Wno-MULTIDRIVEN", "-Wno-WIDTHTRUNC", "-Wno-TIMESCALEMOD", "-Wno-PINMISSING"]

    # determine the shared build dir used for this run
    build_dir = get_shared_build_dir(shared_idx)

    # We only allow one process at a time to touch/use the shared build dir
    shared_lock.acquire()

    # copy static artifacts (scene buffer) into the shared build dir
    shutil.copy(str(proj_path / "data" / "scene_buffer.mem"), build_dir / "scene_buffer.mem")

    # values for parameters defined earlier in the code.
    parameters = {
        "WIDTH": WIDTH,
        "HEIGHT": HEIGHT,
    }

    # ensure sim/ is in path as before
    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "rtx_tb_parallel"

    # get runner for the simulator (same code as original)
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=False,  # allow skip if already built
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=False,
        build_dir=build_dir,
    )
    # Now run the test (the cocotb test saves the chunk to CHUNKS_OUT_DIR)
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=test_file,
        test_args=[],
        waves=False,
    )

    shared_lock.release()


def worker(task):
    """Wrapper used by Pool.map: task = (chunk_idx, start_idx, end_idx, shared_idx)"""

    # Must pass lock to runner so it has shared dir to itself
    chunk_idx, start_idx, end_idx, shared_idx, lock_proxy = task
    runner(start_idx, end_idx, chunk_idx, shared_idx, lock_proxy)
    return chunk_idx


if __name__ == "__main__":
    print(f"Starting parallel render: {WIDTH}x{HEIGHT}, {N_FRAMES} frames, {NUM_CHUNKS_ACTUAL} chunks, {N_SHARED_DIRS} build dirs")

    # Precompute chunk tasks: associate each chunk with a shared build index (round-robin)
    tasks = []
    for chunk_idx, (start_idx, end_idx) in enumerate(CHUNK_RANGES):
        shared_idx = chunk_idx % N_SHARED_DIRS
        tasks.append((chunk_idx, start_idx, end_idx, shared_idx, None))  # lock will be filled below

    manager = Manager()
    # Create lock proxies, one per shared build dir index (up to N_SHARED_DIRS)
    shared_locks = [manager.Lock() for _ in range(N_SHARED_DIRS)]

    # Fill lock proxies into tasks
    tasks_with_locks = []
    for (chunk_idx, start_idx, end_idx, shared_idx, _) in tasks:
        tasks_with_locks.append((chunk_idx, start_idx, end_idx, shared_idx, shared_locks[shared_idx]))

    # Run workers with a process pool
    start_time = time.time()
    with Pool(processes=os.cpu_count()) as pool:
        results = pool.map(worker, tasks_with_locks)

    # Gather chunks and combine
    pixel_chunks = []
    for chunk_idx in range(len(CHUNK_RANGES)):
        chunk_path = CHUNKS_OUT_DIR / f"chunk_{chunk_idx:04}.npy"
        if not chunk_path.exists():
            raise FileNotFoundError(f"Expected chunk file missing: {chunk_path}")
        pixel_chunks.append(np.load(chunk_path))

    pixels_all = np.concatenate(pixel_chunks)
    img = Image.fromarray(pixels_all.reshape((HEIGHT, WIDTH, 3)).astype("uint8"))
    img.save(f"test_rtx_{WIDTH}x{HEIGHT}_f{N_FRAMES}.png")

    elapsed = time.time() - start_time
    print(f"\nSaved image to test_rtx_{WIDTH}x{HEIGHT}_f{N_FRAMES}.png")
    print(f"Render time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    print(f"{N_CHUNKS=}, {N_SHARED_DIRS=}, {WIDTH=}, {HEIGHT=}, {N_FRAMES=}")
