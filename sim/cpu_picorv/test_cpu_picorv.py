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

class Memory():
    def __init__(self, bin_path: str):
        """
        Create memory of 32-bit ints from compiled binary
        """
        with open(bin_path, "rb") as fin:
            self.mem = bytearray(1 << 32)
            data = fin.read()
            print(f"Created memory of {len(data)} bytes")
            self.mem[0:len(data)] = data

    def read(self, addr: int):
        value = int.from_bytes(self.mem[addr:addr+4], byteorder="little", signed=False)
        return value
    
    def write(self, addr: int, data: int, wstrb: int):
        print(f"Writing to addr: {addr:08x}, data: {data:08x}, mask: {wstrb:#x}")
        for i in range(4):
            # Look at mask and write if good
            if wstrb & (1 << i):
                byte_value = (data >> (i * 8)) & 0xFF
                self.mem[addr + i] = byte_value

@cocotb.test()
async def test_module(dut):
    # Create memory
    mem = Memory(Path(__file__).parent.parent.parent / "sw/program.bin")

    # Boot CPU
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await Timer(1, "ps")

    dut.rst.value = 1
    dut.mem_ready.value = 0
    await ClockCycles(dut.clk, 2)

    dut.rst.value = 0
    # Pump cycles and do memory as needed
    for _ in tqdm(range(1000)):
        if dut.mem_valid.value == 0:
            dut.mem_ready.value = 0
            await ClockCycles(dut.clk, 1)
            continue

        mem_addr = dut.mem_addr.value.integer

        if dut.mem_wstrb.value == 0:
            # Read request
            dut.mem_ready.value = 1
            dut.mem_rdata.value = mem.read(mem_addr)
            await ClockCycles(dut.clk, 1)
            dut.mem_ready.value = 0

        else:
            mem.write(mem_addr, dut.mem_wdata.value.integer, dut.mem_wstrb.value.integer)
            dut.mem_ready.value = 1
            dut.mem_rdata.value = 0
            await ClockCycles(dut.clk, 1)
            dut.mem_ready.value = 0

        await ClockCycles(dut.clk, 1)

    addr = 0x40000000
    print(f"Found at addr {addr:08x}: {mem.read(addr)}")


def runner():
    """Module tester."""

    module_name = "picorv32_tb"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "cpu_picorv" / f"picorv32.v",
        proj_path / "hdl" / "cpu_picorv" / f"picorv32_tb.sv"
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
