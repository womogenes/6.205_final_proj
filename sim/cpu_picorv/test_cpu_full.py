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
    # We have our own memory now
    FB_ADDR = 0x10000

    # Boot CPU
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_pixel, 10, units="ns").start())
    await Timer(1, "ps")

    dut.rst.value = 1
    dut.h_count_hdmi.value = 0
    dut.v_count_hdmi.value = 0
    await ClockCycles(dut.clk, 2)

    def extract(data: int, strb: int):
        match strb:
            case 0b1111:
                return data
            case 0b0011:
                return (data & 0x000000FF)
            case 0b1100:
                return (data & 0xFFFF0000) >> 16
            case 0b1000:
                return (data & 0xFF000000) >> 24
            case 0b0100:
                return (data & 0x00FF0000) >> 16
            case 0b0010:
                return (data & 0x0000FF00) >> 8
            case 0b0001:
                return (data & 0x000000FF) >> 0
            case _:
                return 0

    dut.rst.value = 0
    print(f"Running program...")
    write_history = []
    cycle = 0

    while True:
        await ClockCycles(dut.clk_pixel, 1)
        wstrb = dut.cpu_mem_wstrb.value
        wdata = dut.cpu_mem_wdata.value
        addr = dut.cpu_mem_addr.value

        if addr == FB_ADDR and wstrb.integer > 0:
            value = extract(wdata.integer, wstrb.integer)
            write_history.append(value)

        if dut.trap.value or cycle > 1e4:
            # CPU halted
            break
    
        cycle += 1

    # Check if we wrote to frame buf
    print("=" * 64, "\n" * 5)
    print(f"PROGRAM OUTPUT:")
    print(write_history[-1])
    print()
    print(f"Ran in {cycle} cycles")
    print("\n" * 5, "=" * 64)


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

    # compile C program
    sys.path.append(str(proj_path / "sw"))
    from compile import compile

    bin_path, hex_path = compile(
        prog_path=proj_path / "sw/fib/program.c",
        flags="-O0"
    )

    # copy init mem to program
    os.makedirs("sim_build", exist_ok=True)
    shutil.copy(hex_path, "sim_build/prog.mem")
    parameters = {
        "INIT_FILE": "\"prog.mem\""
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
