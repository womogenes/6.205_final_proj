# DISCLAIMER: this test file was almost entirely LLM-generated

import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from proc_types import IType, AluFunc, BrFunc, MemFunc, DecodedInst, ExecInst
from utils import intt
from decoder_test_cases import EXEC_TEST_CASES

test_file = os.path.basename(__file__).replace(".py", "")

def verify_execute(einst: ExecInst, expected: ExecInst):
    """Verify that the execute stage output matches expected values"""
    for field in einst.__dict__:
        actual_val = getattr(einst, field)
        expected_val = getattr(expected, field)

        # Skip checks for certain fields under specific conditions
        if field == "dst" and expected.dst_valid == 0:
            continue
        if field == "data" and (expected.itype == IType.LOAD or expected.itype == IType.BRANCH):
            # For loads, data comes from memory stage
            # For branches, data is don't care (not used)
            continue
        if field == "mem_func" and expected.mem_func == MemFunc.Null:
            continue

        if actual_val != expected_val:
            print(f"Mismatch in field '{field}': expected {expected_val}, got {actual_val}")
            return False
    return True

@cocotb.test()
async def test_module(dut):
    for inst, r_val1, r_val2, pc, expected in EXEC_TEST_CASES:
        dut.inst.value = inst
        dut.r_val1.value = r_val1
        dut.r_val2.value = r_val2
        dut.pc.value = pc

        await Timer(10, "ns")

        try:
            einst = ExecInst(einst=dut.einst.value.binstr)
        except ValueError as e:
            print(f"Encountered error when parsing ExecInst: {dut.einst.value.binstr}")
            print(f"Test case - inst: {inst:032b}, r_val1: {r_val1:#x}, r_val2: {r_val2:#x}, pc: {pc:#x}")
            print(f"Expected: {expected}")
            raise e

        assert verify_execute(einst, expected), \
            f"Failed execute for inst={inst:032b}, r_val1={r_val1:#x}, r_val2={r_val2:#x}, pc={pc:#x}\nExpected:\n  {expected}\nGot:\n  {einst}"

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
