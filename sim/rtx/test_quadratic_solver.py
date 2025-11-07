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
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0

    DELAY_CYCLES = 18

    N_SAMPLES = 1000

    # Generate random (N, 3) tensors for inputs
    A, B, C = np.exp2(np.random.rand(3, N_SAMPLES) * 5 - 4)

    # A, B, C = np.array([[0.0745], [1.4057], [0.2265]])
    # N_SAMPLES = 1

    # Clock in one per cycle brrr
    dut_valid = []
    dut_x0 = []
    dut_x1 = []
    for i in range(N_SAMPLES + DELAY_CYCLES):
        if i < N_SAMPLES:
            a, b, c = A[i], B[i], C[i]
            dut.a.value = make_fp24(a)
            dut.b.value = make_fp24(b)
            dut.c.value = make_fp24(c)

        await ClockCycles(dut.clk, 1)

        if i >= DELAY_CYCLES:
            dut_valid.append(dut.valid.value.integer)
            dut_x0.append(convert_fp24(dut.x0.value))
            dut_x1.append(convert_fp24(dut.x1.value))

    # Get answers!
    await ClockCycles(dut.clk, DELAY_CYCLES * 2)

    dut_valid = np.array(dut_valid)

    dut_x0 = np.array(dut_x0)
    dut_x1 = np.array(dut_x1)

    # print(f"{A=}, {B=}, {C=}")

    # Check correctness
    discr = B**2 - 4*A*C
    mask = discr > 0

    dut._log.info(f"{discr=}")
    dut._log.info(f"{dut_valid=}")

    for i in range(N_SAMPLES):
        if dut_valid[i] != (discr[i] >= 0):
            dut._log.info(f"FAILED TEST CASE: {A[i]=:.3f}, {B[i]=:.3f}, {C[i]=:.3f}, {discr[i]=:.3f}")
            dut._log.info(f"Given answer: {dut_valid[i]}")
            assert False

    # Check answers
    dut._log.info(f"{dut_x0=}")
    dut._log.info(f"{dut_x1=}")
    assert np.all(dut_x0[mask] < dut_x1[mask])

    dut._log.info(f"Avg x0 result: {np.mean(np.abs((A[mask] * (dut_x0[mask]**2)) + (B[mask] * dut_x0[mask]) + C[mask])):.10f}")
    dut._log.info(f"Avg x1 result: {np.mean(np.abs((A[mask] * (dut_x1[mask]**2)) + (B[mask] * dut_x1[mask]) + C[mask])):.10f}")

    # rel_err = np.abs(dut_ans / exp_ans - 1)
    # dut._log.info(f"mean relative error: {np.mean(rel_err) * 100:.6f}%")


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
        proj_path / "hdl" / "math" / "fp24_inv.sv",
        proj_path / "hdl" / "math" / "fp24_inv_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_sqrt.sv",
        proj_path / "hdl" / "rtx" / "quadratic_solver.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "quadratic_solver"
    
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
