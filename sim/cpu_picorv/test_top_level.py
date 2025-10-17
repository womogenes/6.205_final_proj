import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from tqdm import tqdm
import shutil

from enum import Enum
import random
import ctypes
import glob

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    # Boot CPU
    cocotb.start_soon(Clock(dut.clk_100mhz, 10, units="ns").start())
    await Timer(100, "ps")

    dut.btn[0].value = 1
    await ClockCycles(dut.clk_100mhz, 10)
    dut.btn[0].value = 0

    while True:
        await ClockCycles(dut.clk_100mhz, 100)
        if dut.my_cpu.trap == 1:
            break


def runner():
    """Module tester."""

    module_name = "top_level"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent

    sys.path.append(str(proj_path / "sim" / "model"))

    sources = [
        *glob.glob(str(proj_path / "hdl/mem/*.v")),
        proj_path / "hdl" / "cpu_picorv" / f"picorv32.v",
        proj_path / "hdl" / "cpu_picorv" / f"cpu.sv",
        # *glob.glob(str(proj_path / "hdl/hdmi/*.v")),
        *glob.glob(str(proj_path / "hdl/hdmi/*.sv")),
        proj_path / "hdl" / f"top_level.sv"
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.

    # compile C program
    sys.path.append(str(proj_path / "sw"))
    from compile import compile

    bin_path, hex_path = compile(
        # prog_path=proj_path / "sw/test/program.s",
        prog_path=proj_path / "sw/gol/program.c",
        flags="-O0"
        # flags="-O3"
    )

    # copy init mem to program
    os.makedirs("sim_build", exist_ok=True)
    shutil.copy(hex_path, "sim_build/prog.mem")
    parameters = {}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = module_name
    
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
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
