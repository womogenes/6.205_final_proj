import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.runner import get_runner

from enums import IType, AluFunc, BrFunc, MemFunc
from utils import intt

test_file = os.path.basename(__file__).replace(".py", "")

class DecodedInst():
    def __init__(self, dinst: str = None, **kwargs):
        self.itype = kwargs.get("itype") or IType(intt(dinst[0:4]))
        self.alufunc = kwargs.get("alufunc") or AluFunc(intt(dinst[4:8]))
        self.brfunc = kwargs.get("brfunc") or BrFunc(intt(dinst[8:11]))
        self.memfunc = kwargs.get("memfunc") or MemFunc(intt(dinst[11:14]))
        self.dst = kwargs.get("dst") or intt(dinst[14:19])
        self.dst_valid = kwargs.get("dst_valid") or intt(dinst[19])
        self.src1 = kwargs.get("src1") or intt(dinst[20:25])
        self.src2 = kwargs.get("src2") or intt(dinst[25:30])
        self.imm = kwargs.get("imm") or intt(dinst[30:62])
    
    def __str__(self):
        return f"DecodedInst(itype={self.itype}, alufunc={self.alufunc}, brfunc={self.brfunc}, memfunc={self.memfunc}, dst={self.dst}, dst_valid={self.dst_valid}, src1={self.src1}, src2={self.src2}, imm={self.imm})" 


TEST_CASES = [
    (
        0b0000_0000_0000_0000_0000_0001_00001_0110111,
        DecodedInst(itype=IType.LUI, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null, dst=1, dst_valid=1, src1=-1, src2=-1, imm=1 << 12)
    ),
]

def verify_decode(dinst: DecodedInst, expected: DecodedInst):
    for field in dinst.__dict__:
        if getattr(dinst, field) != getattr(expected, field):
            return False
    return True
    

@cocotb.test()
async def test_module(dut):
    for inst, expected in TEST_CASES:
        dut.inst.value = inst
        await Timer(10, "ns")
        assert verify_decode(DecodedInst(dut.dinst.value.binstr), expected), \
            f"Failed to decode {inst:32b}. Expected:\n  {expected}\nGot:\n  {DecodedInst(dut.dinst.value.binstr)}"


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
