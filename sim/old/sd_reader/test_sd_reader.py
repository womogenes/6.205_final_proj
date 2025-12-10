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

# MUST START ON FALLING EDGE
async def send_byte(dut, byte):
  spi_response = int('{:08b}'.format(byte)[::-1], 2)
  for b in range(8):
    dut.cipo.value = spi_response & 0x1
    spi_response = spi_response >> 1
    await RisingEdge(dut.dclk)
    await FallingEdge(dut.dclk)

# this module below is a simple "fake" spi module written in Python that we can...
# test our design against.
async def test_spi_device(dut):
  cmd_count = 0
  spi_response = 0x1
  while True:
    await FallingEdge(dut.cs) #listen for falling CS
    dut.cipo.value = 0 # feed in a zero
    dut._log.info(f"SPI transaction started")
    data_out = 0
    # read data in
    for b in range(48):
      await RisingEdge(dut.dclk)
      bit = dut.copi.value.integer #grab value:
      data_out = (data_out << 1) | bit
      if b < 47:
         await FallingEdge(dut.dclk)

    dut._log.info(f"SPI peripheral Device received data: {hex(data_out)}")

    await FallingEdge(dut.clk)

    cmd_count += 1
    spi_response = 0xFF
    # check diff values of data_out (cmd)
    if data_out == 0x694000000077:
      if cmd_count >= 9:
        #NOTE response is in reverse order
        spi_response = 0x00
      else:
        spi_response = 0x80
      await send_byte(dut, spi_response)

    if data_out & 0xFF_00000000_00 == 0x51_00000000_00:

      addr = (data_out & 0x00_FFFFFFFF_00) >> 8
      dut._log.info(f"Memory access request at address: {hex(addr)}")

      wait_count = 4
      for w in range(wait_count):
        spi_response = 0xFF
        if w == wait_count - 1:
            # return start signal
            spi_response = 0xFE
        await send_byte(dut, spi_response)

      # send response data
      for d in range(512):
        spi_response = (addr >> (8 * (d % 4))) & 0xFF
        await send_byte(dut, spi_response)
      for c in range(2):
        spi_response = 0xFF
        await send_byte(dut, spi_response)
      dut.cipo = 0
        

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

    DCLK_START_PERIOD = 8
    DCLK_READ_PERIOD = 4
    
    dut.rst.value = 0 #un reset device

    await ClockCycles(dut.clk, 1000000)
    dut.block_addr.value = 0x123456 >> 1
    dut.trigger.value = True
    await ClockCycles(dut.clk, 10000)
    


def runner():
    """Module tester."""

    module_names = ["sd_reader", "spi_con_continuous"]

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "sd_reader" /f"{mn}.sv" for mn in module_names]
    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {}

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
