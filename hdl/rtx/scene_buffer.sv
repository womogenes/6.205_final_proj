`default_nettype none

module scene_buffer #(
  parameter INIT_FILE = ""
) (
  input wire clk,
  input wire rst,
  input wire [OBJ_IDX_WIDTH-1:0] num_objs,

  // Object overwrite flashing
  input wire flash_obj_wen,
  input wire [OBJ_IDX_WIDTH-1:0] flash_obj_idx,
  input wire [$bits(object)-1:0] flash_obj_data,

  output object obj
);
  logic [$clog2(MAX_NUM_OBJS)-1:0] obj_idx;

  always_ff @(posedge clk) begin
    if (rst) begin
      obj_idx <= 0;
    end else begin
      if (obj_idx >= num_objs - 1) begin
        obj_idx <= 0;
      end else begin
        obj_idx <= obj_idx + 1;
      end
    end
  end

  // Read out objects from memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH($bits(object)),
    .RAM_DEPTH(MAX_NUM_OBJS),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
  ) scene_buf_mem (
    // Reprogramming write
    .addra(flash_obj_idx),
    .clka(clk),
    .wea(flash_obj_wen),
    .dina(flash_obj_data),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(),

    // Output port
    .addrb(obj_idx),
    .dinb(),
    .clkb(clk),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(obj)
  );
  
endmodule

`default_nettype wire
