`default_nettype none

module material_dictionary #(
  parameter INIT_FILE = ""
) (
  input wire clk,
  input wire rst,

  // Object overwrite flashing
  input wire flash_mat_wen,
  input wire [7:0] flash_mat_idx,
  input wire [$bits(material)-1:0] flash_mat_data,

  input wire [7:0] mat_idx,
  output material mat
);
  // Read out materials from memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH($bits(material)),
    .RAM_DEPTH(256),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
  ) scene_buf_mem (
    // Reprogramming write
    .addra(flash_mat_idx),
    .clka(clk),
    .wea(flash_mat_wen),
    .dina(flash_mat_data),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(),

    // Output port
    .addrb(mat_idx),
    .dinb(),
    .clkb(clk),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(mat)
  );
  
endmodule

`default_nettype wire
