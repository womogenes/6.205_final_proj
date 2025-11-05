`default_nettype none

module scene_buffer #(
  parameter INIT_FILE = ""
) (
  input wire clk,
  input wire rst,
  input wire [3:0] obj_idx,

  output object obj,
  output logic [3:0] num_objs
);

  // Read out objects from memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(649),
    .RAM_DEPTH(16),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
  ) main_mem (
    // CPU read/write
    .addra(),
    .clka(clk),
    .wea(1'b0),
    .dina(),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(),

    // HDMI read (frame buffer)
    .addrb(obj_idx),
    .dinb(1'b0),
    .clkb(clk),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(obj)
  );
  
endmodule

`default_nettype wire
