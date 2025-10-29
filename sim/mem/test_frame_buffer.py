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

async def hdmi_reader(dut):
    await FallingEdge(dut.rst)
    while True:
        image_drawn = [[' ' for i in range(20)] for j in range(20)]
        for v in range(25):
            for h in range(25):
                dut.h_count_hdmi.value = h
                dut.v_count_hdmi.value = v
                dut.active_draw_hdmi.value = h < 20 and v < 20

                if dut.pixel_out_valid.value:
                    # dut._log.info('%s', dut.pixel_out_color.value.binstr)
                    image_drawn[dut.pixel_out_v_count.value][dut.pixel_out_h_count.value] = \
                        hex(int(dut.pixel_out_color.value.binstr[:4], 2))[2:]
                await RisingEdge(dut.clk_hdmi)
                await FallingEdge(dut.clk_hdmi)
        for line in image_drawn:
            dut._log.info("%s" * 20, *tuple(line))
            pass

async def rtx_renderer(dut):
    await FallingEdge(dut.rst)
    frames = 0
    while True:

        for v in range(20):
            for h in range(20):
                dut.pixel_h.value = h
                dut.pixel_v.value = v

                await ClockCycles(dut.clk_rtx, 3, False)
                dut.new_color_valid.value = 1
                dut.new_color.value = (frames + 8) * (2**20)

                await RisingEdge(dut.clk_rtx)
                await FallingEdge(dut.clk_rtx)
                dut.new_color_valid.value = 0
        frames += 1
        frames %= 7

@cocotb.test()
async def test_module(dut):
    """cocotb test for the frame buffer module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_hdmi, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_rtx, 2, units="ns").start())
    cocotb.start_soon(hdmi_reader(dut))
    cocotb.start_soon(rtx_renderer(dut))


    dut._log.info("Holding reset...")
    dut.rst.value = 1
    dut.active_draw_hdmi.value = 0
    dut.new_color_valid.value = 0
    dut.pixel_h.value = 0
    dut.pixel_v.value = 0
    await ClockCycles(dut.clk_hdmi, 3, False)
    dut.rst.value = 0
    await ClockCycles(dut.clk_hdmi, 25*25*15)


def runner():
    """Module tester."""

    module_names = ["frame_buffer"]

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "mem" /f"{mn}.sv" for mn in module_names]
    sources.append(proj_path / "hdl" / "mem" / "xilinx_true_dual_port_read_first_2_clock_ram.v")
    sources.append(proj_path / "hdl" / "pipeline.sv")

    build_test_args = ["-Wall"]

    # values for parameters defined earlier in the code.
    parameters = {"SIZE_H": 20, "SIZE_V": 20, "DATA_WIDTH": 24}

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
