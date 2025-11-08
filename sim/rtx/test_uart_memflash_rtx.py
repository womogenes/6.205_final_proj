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

sys.path.append(Path(__file__).resolve().parent.parent._str)
from utils import convert_fp24, make_fp24, convert_fp24_vec3

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):

    # Reset controller
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await Timer(1, "ps")

    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    dut.uart_rx_valid.value = 0

    await ClockCycles(dut.clk, 20)

    async def send_byte(byte):
        dut.uart_rx_valid.value = 1
        dut.uart_rx_byte.value = byte
        await ClockCycles(dut.clk, 1)
        dut.uart_rx_valid.value = 0
        await ClockCycles(dut.clk, 8)

    # Start byte
    await send_byte(0xAA)

    # Camera data
    cam_data = 0x012345_abcdef_678900
    for i in range(12):
        # lsb-first
        await send_byte((cam_data >> (i * 8)) & 0xFF)


def runner():
    """Module tester."""

    module_name = "uart_memflash"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "uart" / f"uart_memflash_rtx.sv"
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
