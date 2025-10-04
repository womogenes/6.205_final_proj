import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from tqdm import tqdm

from enum import Enum
import random
import ctypes

test_file = os.path.basename(__file__).replace(".py", "")

class AluFunc(Enum):
    ADD = 0
    SUB = 1
    AND = 2
    OR = 3
    XOR = 4
    SLT = 5
    SLTU = 6
    SLL = 7
    SRL = 8
    SRA = 9

@cocotb.test()
async def test_module(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await Timer(1, "ps")

    # Run random tests
    dut.w_en = 0

    dut.r_idx1 = 0
    await ClockCycles(dut.clk, 1)
    assert dut.dout1.value == 0

    dut.w_en = 1
    dut.w_idx = 5
    dut.w_data = 0xDEADBEEF
    dut.r_idx1 = 5
    await ClockCycles(dut.clk, 1)
    dut.w_en = 0
    await ClockCycles(dut.clk, 1)

    dut.w_en = 1
    dut.w_idx = 31
    dut.w_data = 0xFEEDBEEF
    dut.r_idx2 = 31
    await ClockCycles(dut.clk, 1)
    dut.w_en = 0
    await ClockCycles(dut.clk, 1)

    assert dut.dout2.value == 0xFEEDBEEF


def runner():
    """Module tester."""

    module_name = "reg_file"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "cpu" / f"{module_name}.sv"]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
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
