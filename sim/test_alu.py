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
    A_test_range = random.sample(range(0, (1<<32)), k=1_0)
    B_test_range = list(range(0, 32)) + random.sample(range(0, (1<<32)), k=1_0)
    
    for A in tqdm(A_test_range, ncols=70):
        for B in B_test_range:
            A_signed = ctypes.c_int32(A).value
            B_signed = ctypes.c_int32(B).value

            dut.a.value = A
            dut.b.value = B

            mask = 0xFFFFFFFF

            dut.func.value = AluFunc.ADD.value
            await Timer(10, "ns")
            assert dut.res.value == (A + B) & mask, ("ADD broken", A, B)

            dut.func.value = AluFunc.SUB.value
            await Timer(10, "ns")
            assert dut.res.value == (A - B) & mask, ("SUB broken", A, B)

            dut.func.value = AluFunc.AND.value
            await Timer(10, "ns")
            assert dut.res.value == (A & B) & mask, ("AND broken", A, B)

            dut.func.value = AluFunc.OR.value
            await Timer(10, "ns")
            assert dut.res.value == (A | B) & mask, ("OR broken", A, B)

            dut.func.value = AluFunc.XOR.value
            await Timer(10, "ns")
            assert dut.res.value == (A ^ B) & mask, ("XOR broken", A, B)

            dut.func.value = AluFunc.SLT.value
            await Timer(10, "ns")
            assert dut.res.value == (A_signed < B_signed) & mask, ("SLT broken", A, B)

            dut.func.value = AluFunc.SLTU.value
            await Timer(10, "ns")
            assert dut.res.value == (A < B) & mask, ("SLTU broken", A, B)

            dut.func.value = AluFunc.SLL.value
            await Timer(10, "ns")
            assert dut.res.value == (A << B) & mask, ("SLL broken", A, B)

            dut.func.value = AluFunc.SRL.value
            await Timer(10, "ns")
            assert dut.res.value == (A >> B) & mask, ("SLR broken", A, B)

            dut.func.value = AluFunc.SRA.value
            await Timer(10, "ns")
            assert dut.res.value == (A_signed >> B) & mask, ("SLR broken", A, B)


def runner():
    """Module tester."""

    module_name = "alu"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
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
