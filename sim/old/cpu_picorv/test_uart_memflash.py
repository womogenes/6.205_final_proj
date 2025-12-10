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

test_file = os.path.basename(__file__).replace(".py", "")

@cocotb.test()
async def test_module(dut):
    addr_base = 0x100000
    msg_len = 400

    # Reset controller
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await Timer(1, "ps")

    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    dut.uart_rx_valid.value = 0

    await ClockCycles(dut.clk, 20)

    async def send_byte(byte):
        dut.uart_rx_valid = 1
        dut.uart_rx_byte = byte
        await ClockCycles(dut.clk, 1)
        dut.uart_rx_valid = 0
        await ClockCycles(dut.clk, 8)

    # Start byte
    await send_byte(0xAA)

    # Address
    for i in range(4):
        # lsb-first
        await send_byte((addr_base >> (i * 8)) & 0xFF)
    
    # Length
    for i in range(4):
        # lsb-first
        await send_byte((msg_len >> (i * 8)) & 0xFF)

    # Bytestream
    assert msg_len % 4 == 0
    for i in range(msg_len // 4):
        for j in range(4):
            await send_byte((i >> (j * 8)) & 0xFF)

    return



def runner():
    """Module tester."""

    module_name = "uart_memflash"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "uart" / f"uart_memflash.sv"
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
