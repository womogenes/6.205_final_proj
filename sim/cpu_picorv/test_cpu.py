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

@cocotb.test()
async def test_module(dut):
    # We have our own memory now

    # Boot CPU
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_pixel, 10, units="ns").start())
    await Timer(1, "ps")

    dut.rst.value = 1
    dut.h_count_hdmi.value = 0
    dut.v_count_hdmi.value = 0
    await ClockCycles(dut.clk, 2)

    dut.rst.value = 0
    # Wait for reset to clear through memory pipeline
    for _ in tqdm(range(1_00)):
        await ClockCycles(dut.clk_pixel, 100)

    # Read stuff from valid addresses (program is at address 0)
    base_addr = 0x0
    for i in range(10):
        addr = base_addr + i
        dut.h_count_hdmi.value = addr
        dut.v_count_hdmi.value = 0
        # Wait for memory read latency (2 cycles for HIGH_PERFORMANCE mode)
        await ClockCycles(dut.clk_pixel, 3)
        print(f"Address {addr:04x}: pixel = {dut.pixel.value}")


def runner():
    """Module tester."""

    module_name = "cpu"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "mem" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
        proj_path / "hdl" / "mem" / "xilinx_single_port_ram_read_first.v",
        proj_path / "hdl" / "cpu_picorv" / f"picorv32.v",
        proj_path / "hdl" / "cpu_picorv" / f"cpu.sv"
    ]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    print("HELLO WORLD", os.path.abspath("../../sw/program.mem"))
    parameters = {
        "INIT_FILE": "program.mem"
    }

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
