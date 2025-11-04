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
import math

import matplotlib.pyplot as plt

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24, make_fp24_vec3, convert_fp24_vec3

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """
    Test module: vec3 addition using fp24
    """
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3)
    dut.rst.value = 0

    DELAY_CYCLES = 21

    N_SAMPLES = 1000

    # Generate random (N, 3) tensors for inputs
    async def mean_rel_err(vec_scale: float):
        a_vecs = np.exp2((np.random.rand(N_SAMPLES, 3) - 0.5) * 2 * vec_scale)
        a_vecs_fp24 = list(map(make_fp24_vec3, a_vecs))

        # Clock in one per cycle brrr
        dut_ans = []
        for i in range(N_SAMPLES):
            a_fp24_vec3 = a_vecs_fp24[i]

            dut.v.value = a_fp24_vec3

            await ClockCycles(dut.clk, 1)
            dut_ans.append(convert_fp24_vec3(dut.normed.value))

        for _ in range(DELAY_CYCLES):
            await ClockCycles(dut.clk, 1)
            dut_ans.append(convert_fp24_vec3(dut.normed.value))

        # Get answers!
        await ClockCycles(dut.clk, DELAY_CYCLES * 2)
        dut_ans = np.array(dut_ans[DELAY_CYCLES:])
        exp_ans = a_vecs / np.linalg.norm(a_vecs, axis=1, keepdims=True)

        rel_err = np.abs(dut_ans / exp_ans - 1)
        dut._log.info(f"vector scale: {scale:>2}\tmean relative error: {np.mean(rel_err) * 100:.6f}%")

        return np.mean(rel_err)

    for scale in range(1, 63):
        await mean_rel_err(scale)

def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "pipeline.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "math" / "fp24_shift.sv",
        proj_path / "hdl" / "math" / "fp24_add.sv",
        proj_path / "hdl" / "math" / "fp24_mul.sv",
        proj_path / "hdl" / "math" / "fp24_inv_sqrt.sv",
        proj_path / "hdl" / "math" / "fp24_vec3_ops.sv",
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "fp24_vec3_normalize"
    
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
