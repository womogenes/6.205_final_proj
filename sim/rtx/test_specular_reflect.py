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
from utils import convert_fp, make_fp, convert_fp_vec3, make_fp_vec3

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst.value = 0

    DELAY_CYCLES = 8

    # Generate inputs
    N_SAMPLES = 1000
    A = np.exp2((np.random.rand(N_SAMPLES, 3) - 0.5) * 31)
    B = np.exp2((np.random.rand(N_SAMPLES, 3) - 0.5) * 31)

    # N_SAMPLES = 1
    # A = [(1/np.sqrt(2), -1/np.sqrt(2), 0)]
    # B = [(0, 1, 0)]

    # Clock in one per cycle brrr
    dut_ans = []
    for i in range(N_SAMPLES + DELAY_CYCLES):
        if i < N_SAMPLES:
            dut.in_dir.value = make_fp_vec3(A[i])
            dut.normal.value = make_fp_vec3(B[i])

        await ClockCycles(dut.clk, 1)

        if i >= DELAY_CYCLES:
            dut_ans.append(convert_fp_vec3(dut.out_dir.value.integer))

    # Get answers!
    await ClockCycles(dut.clk, DELAY_CYCLES * 2)

    # Expected answers...
    ray_dir = np.array(A)
    normal = np.array(B)
    exp_ans = ray_dir + normal * (-2 * (ray_dir * normal).sum(axis=1, keepdims=True))

    dut._log.info(f"Mean error: {np.mean(abs(dut_ans / exp_ans - 1)) * 100:.6f}%")


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
        proj_path / "hdl" / "math" / "fp_shift.sv",
        proj_path / "hdl" / "math" / "fp_add.sv",
        proj_path / "hdl" / "math" / "fp_mul.sv",
        proj_path / "hdl" / "math" / "fp_inv_sqrt.sv",
        proj_path / "hdl" / "math" / "fp_vec3_ops.sv",
        proj_path / "hdl" / "math" / "specular_reflect.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "specular_reflect"
    
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
