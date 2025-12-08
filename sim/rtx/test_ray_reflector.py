import os
import sys
import glob

from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

import numpy as np
import matplotlib.pyplot as plt

sys.path.append(Path(__file__).resolve().parent.parent.parent._str)
from sim.utils import convert_fp_vec3, make_fp, make_fp_vec3, make_material

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    """cocotb test for ray_reflector pipelining"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut._log.info("Holding reset...")
    dut.rst.value = 1
    dut.lfsr_seed.value = int.from_bytes(os.urandom(8))
    await ClockCycles(dut.clk, 50)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 5)

    DELAY_CYCLES = 37
    N_SAMPLES = 1000

    mat_types = [
        {
            "ray_dir": [0, -1, 0],
            "hit_normal": [1/np.sqrt(2), 1/np.sqrt(2), 0],
            "income_light": [1, 0, 1],
            "mat": make_material(
                color=make_fp_vec3((1.0, 0.0, 0.0)),
                spec_color=make_fp_vec3((1.0, 0.0, 0.0)),
                emit_color=make_fp_vec3((0.0, 0.0, 0.0)),
                specular=255,
                smooth=make_fp(0.9),
            )
        },
        {
            "ray_dir": [0, -1, 0],
            "hit_normal": [0, 1/np.sqrt(2), -1/np.sqrt(2)],
            "income_light": [0, 1, 1],
            "mat": make_material(
                color=make_fp_vec3((0.0, 0.0, 1.0)),
                spec_color=make_fp_vec3((0.0, 0.0, 1.0)),
                emit_color=make_fp_vec3((0.0, 0.0, 0.0)),
                specular=255,
                smooth=make_fp(1.0),
            )
        },
        {
            "ray_dir": [1, 0, 0],
            "hit_normal": [-1/np.sqrt(2), 1/np.sqrt(2), 0],
            "income_light": [1, 1, 0],
            "mat": make_material(
                color=make_fp_vec3((0.0, 1.0, 0.0)),
                spec_color=make_fp_vec3((0.0, 1.0, 0.0)),
                emit_color=make_fp_vec3((0.0, 0.0, 0.0)),
                specular=255,
                smooth=make_fp(0.9),
            )
        },
    ]

    # ONE INPUT PER CYCLE!!
    dut.hit_valid.value = 1

    dirs, colors = [], []

    for i in range(N_SAMPLES + DELAY_CYCLES):
        if i < N_SAMPLES:
            mat = mat_types[i % 3]
            dut.ray_dir.value = make_fp_vec3(mat["ray_dir"])
            dut.hit_normal.value = make_fp_vec3(mat["hit_normal"])
            dut.hit_mat.value = mat["mat"]
            dut.ray_color.value = make_fp_vec3((1.0, 1.0, 1.0))
            dut.income_light.value = make_fp_vec3(mat["income_light"])
            dut.hit_pos.value = make_fp_vec3((0.0, 0.0, 0.0))

        await ClockCycles(dut.clk, 1)

        if i >= DELAY_CYCLES:
            idx = i - DELAY_CYCLES
            new_color = convert_fp_vec3(dut.new_color.value)
            new_income = convert_fp_vec3(dut.new_income_light.value)
            new_dir = convert_fp_vec3(dut.new_dir.value)
            mat_type = ["red diffuse", "blue spec", "green diffuse"][idx % 3]
            dut._log.info(f"{mat_type:15s} | {new_color=} {new_income=} {new_dir=}")
            dirs.append(new_dir)
            colors.append(new_income)

    dut.hit_valid.value = 0
    await ClockCycles(dut.clk, 10)

    # plot
    fig = plt.figure()
    ax = fig.add_subplot(projection='3d')
    dirs = np.array(dirs)
    colors = np.array(colors)
    ax.scatter(dirs[:,0], dirs[:,1], dirs[:,2], c=colors, s=20)
    plt.show()


def runner():
    """Module tester."""

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "types" / "types.sv",
        proj_path / "hdl" / "pipeline.sv",
        *glob.glob(f'{proj_path}/hdl/rng/*.sv', recursive=True),
        *glob.glob(f'{proj_path}/hdl/math/*.sv', recursive=True),
        proj_path / "hdl" / "rtx" / "ray_reflector.sv",
    ]
    build_test_args = [
        "-Wno-WIDTHEXPAND",
        "-Wno-MULTIDRIVEN",
        "-Wno-WIDTHTRUNC",
        "-Wno-TIMESCALEMOD",
        "-Wno-PINMISSING",
        "-Wno-BLKSEQ",
    ]

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
