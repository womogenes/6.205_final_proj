# DISCLAIMER: this test file was almost entirely LLM-generated

import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from proc_types import IType, AluFunc, BrFunc, MemFunc, DecodedInst
from utils import intt

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    dut.inst.value = 0
    dut.r_val1.value = 0
    dut.r_val2.value = 0
    dut.pc.value = 0

    await Timer(10, "ns")
    print(dut.einst.value.binstr)

def runner():
    """Module tester."""

    module_name = "execute_tb"

    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "cpu" / "alu.sv",
        proj_path / "hdl" / "cpu" / "mem_types.sv",
        proj_path / "hdl" / "cpu" / "proc_types.sv",
        proj_path / "hdl" / "cpu" / "decoder.sv", 
        proj_path / "hdl" / "cpu" / "execute.sv",
        proj_path / "hdl" / "cpu" / "execute_tb.sv",
    ]
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
