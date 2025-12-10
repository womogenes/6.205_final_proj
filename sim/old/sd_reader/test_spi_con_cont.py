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

# this module below is a simple "fake" spi module written in Python that we can...
# test our design against.
async def test_spi_device(dut):
  count = 0
  count_max = 16 #change for different sizes
  SPI_RESP_MSG = int('{:048b}'.format(0x00000000DEAD)[::-1], 2)
  while True:
    await FallingEdge(dut.cs) #listen for falling CS
    dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
    # dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
    count+=1
    data_out = 0
    while dut.cs.value.integer == 0:
      await RisingEdge(dut.dclk)
      bit = dut.copi.value.integer #grab value:
    #   dut._log.info(f"SPI peripheral Device Receiving: {bit}")
      data_out = (data_out << 1) | bit
      await FallingEdge(dut.dclk)
      dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
    #   dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
      dut._log.info(f"SPI peripheral Device received data: {hex(data_out)}")
      count+=1
    count = 0
    dut._log.info(f"SPI peripheral Device received data: {hex(data_out)}")

@cocotb.test()
async def test_module(dut):
    """cocotb test for the SPI module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    cocotb.start_soon(test_spi_device(dut))
    dut._log.info("Holding reset...")
    dut.rst.value = 1
    dut.trigger.value = 0
    await ClockCycles(dut.clk, 3) #wait three clock cycles
    assert dut.cs.value.integer==1, "cs is not 1 on reset!"
    await  FallingEdge(dut.clk)

    SPI_DCLK_PERIOD = 8

    dut.rst.value = 0 #un reset device
    # send first byte
    dut.data_in.value = 0xBE
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 - 2)
    # send second byte
    dut.data_in.value = 0xEF
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 - 2)
    # send third byte
    dut.data_in.value = 0xCA
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 - 2)
    # send fourth byte
    dut.data_in.value = 0xFE
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 - 2)
    # await fifth byte
    dut.data_in.value = 0x00
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 - 2)
    # await sixth byte
    dut.data_in.value = 0x00
    dut.trigger.value = 1
    await ClockCycles(dut.clk, 2)
    dut.trigger.value = 0
    await ClockCycles(dut.clk, SPI_DCLK_PERIOD * 8 + 8)

    


def runner():
    """Module tester."""

    module_name = "spi_con_continuous"

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / f"{module_name}.sv"]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {"DATA_WIDTH": 8, "DATA_CLK_PERIOD": 8}

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
