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

test_file = os.path.basename(__file__).replace(".py", "")

def lazy_mult(a, b, ignored=0, bits=16):
    a_bin = f"{a:0{bits}b}"
    result = 0
    for bit in range(bits):
        if a_bin[-bit - 1] == '1':
            b_truncated = int(f"{b:0{bits}b}"[:bits - max(ignored - bit, 0)] + '0' * max(ignored - bit, 0), 2)
            result += b_truncated * (2 ** bit)
    return int(f"{result:032b}", 2)

@cocotb.test()
async def test_module(dut):
    """cocotb test for the lazy mult module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3, False)
    dut.rst.value = 0
    
    accumulated_error = 0
    error_count = 0
    worst_error = 0

    for a in range(2**8):
        for b in range(2**8):

            dut.din_a.value = a
            dut.din_b.value = b
            dut.din_valid.value = 1

            await ClockCycles(dut.clk, 1, False)
            lazy_mult_result = lazy_mult(a, b, ignored=8, bits=8) // (2**8)
            correct_result = a * b // (2**8)
            if lazy_mult_result != correct_result:
                # dut._log.info("error multiplying %d * %d = %d, got %d", a, b, correct_result, lazy_mult_result)
                accumulated_error += correct_result - lazy_mult_result
                error_count += 1
                worst_error = max(worst_error, correct_result - lazy_mult_result)

            assert dut.dout.value == lazy_mult_result
            
    dut._log.info("error count: %f, error rate: %f, avg error: %f, avg error error: %f, worst error: %d", 
                  error_count,
                  error_count / (2**16),
                  accumulated_error / (2**16), 
                  accumulated_error / error_count,
                  worst_error)
    


def runner():
    """Module tester."""

    module_names = ["lazy_multiplier"]

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "math" /f"{mn}.sv" for mn in module_names]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {"WIDTH_A": 8, "WIDTH_B": 8, "BITS_DROPPED": 8}

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = module_names[0]
    
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
