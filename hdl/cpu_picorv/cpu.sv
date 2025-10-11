// Uses picorv32 and memory to make a full CPU
// Handles MMIO

`default_nettype none

module cpu #(
  parameter INIT_FILE = ""
) (
  input wire clk,
  input wire rst,

  // Output control
  input wire clk_pixel,
  input wire [10:0] h_count_hdmi,
  input wire [9:0] v_count_hdmi,

  // Outputs
  output logic [7:0] pixel
);
  localparam integer FB_ADDR = 'h41000;
  localparam integer MEM_SIZE = 1024 * 1024;
  localparam integer ADDR_WIDTH = $clog2(MEM_SIZE);

  // Fixed at 320x180
  logic [ADDR_WIDTH-1:0] pixel_addr;
  always_comb begin
    pixel_addr = ((v_count_hdmi >> 2) * 320 + (h_count_hdmi >> 2));
  end

  // CPU
  // picorv32 #(
  //   .REGS_INIT_ZERO(1),
  //   .STACKADDR(32'h ffff_ffff)
  // ) cpu (
  //   .clk(clk),
  //   .resetn(~rst),

  //   // Memory interface
  //   .mem_valid(mem_valid),
  //   .mem_instr(mem_instr),
  //   .mem_ready(mem_ready),
  //   .mem_addr(mem_addr),
  //   .mem_wdata(mem_wdata),
  //   .mem_wstrb(mem_wstrb),
  //   .mem_rdata(mem_rdata)
  // );

  // Memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(MEM_SIZE), // arbitrary memory width for now (21 bit address space)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
  ) main_mem (
    // CPU read/write
    .addra('b0),
    .clka(clk),
    .wea(1'b0),
    .dina('b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(),
    
    // HDMI read (frame buffer)
    .addrb(pixel_addr),
    .dinb('b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(pixel)
  );
  // ====================

endmodule

`default_nettype wire
