import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from proc_types import IType, AluFunc, BrFunc, MemFunc, DecodedInst
from utils import intt
from decoder_test_cases import TEST_CASES

test_file = os.path.basename(__file__).replace(".py", "")

def verify_decode(dinst: DecodedInst, expected: DecodedInst):
    for field in dinst.__dict__:
        if getattr(dinst, field) != getattr(expected, field):
            # dst field only needs to match if valid
            if field == "imm" and expected.itype != IType.OPIMM:
                continue
            if field == "dst" and (expected.dst_valid == 0 or expected.dst == -1):
                continue
            if field == "alu_func" and expected.alu_func == AluFunc.Null:
                continue
            if field == "br_func" and expected.br_func == BrFunc.Null:
                continue
            if field == "mem_func" and expected.mem_func == MemFunc.Null:
                continue
            if field == "src1" and expected.src1 == -1:
                continue
            if field == "src2" and expected.src2 == -1:
                continue

            print(f"violation encountered in field {field}")
            return False
    return True
    

@cocotb.test()
async def test_module(dut):
    for inst, expected in TEST_CASES:
        dut.inst.value = inst
        await Timer(10, "ns")
        
        try:
            dinst = DecodedInst(dut.dinst.value.binstr)
            print(dinst)
            
        except ValueError as e:
            print(f"Encountered error when decoding {dut.dinst.value.binstr}")
            print(f"Test case: {expected}")
            raise e

        assert verify_decode(dinst, expected), \
            f"Failed to decode {inst:032b}. Expected:\n  {expected}\nGot:\n  {dinst}"


def runner():
    """Module tester."""

    module_name = "decoder"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "cpu" / "alu.sv",
        proj_path / "hdl" / "cpu" / "mem_types.sv",
        proj_path / "hdl" / "cpu" / "proc_types.sv",
        proj_path / "hdl" / "cpu" / "decoder.sv",
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
