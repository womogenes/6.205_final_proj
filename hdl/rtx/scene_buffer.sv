`default_nettype none

module scene_buffer #(
  parameter INIT_FILE = ""
) (
  input wire clk,
  input wire rst,
  input wire [$clog2(SCENE_BUFFER_DEPTH)-1:0] obj_idx,

  output object obj,
  output logic obj_last,

  // TODO: remove debug signals
  output logic is_trig,            // 1 bit
  output material mat,             // 264 bits
  output fp24_vec3 [2:0] trig,     // 216 bits
  output fp24_vec3 trig_norm,      // 72 bits
  output fp24_vec3 sphere_center,  // 72 bits
  output fp24 sphere_rad_sq,       // 24 bits
  output fp24 sphere_rad_inv       // 24 bits
);
  // FOR DEBUG ONLY
  // TODO: remove debug signals
  assign mat = obj.mat;
  assign sphere_center = obj.sphere_center;
  assign sphere_rad_sq = obj.sphere_rad_sq;
  assign sphere_rad_inv = obj.sphere_rad_inv;

  // Tell outside world whether this object is the last one
  pipeline #(.WIDTH(1), .DEPTH(2)) obj_last_pipe (
    .clk(clk),
    .in(obj_idx == SCENE_BUFFER_DEPTH - 1),
    .out(obj_last)
  );

  // Read out objects from memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SCENE_BUFFER_WIDTH),
    .RAM_DEPTH(SCENE_BUFFER_DEPTH),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
  ) scene_buf_mem (
    // Reprogramming write
    .addra(),
    .clka(clk),
    .wea(1'b0),
    .dina(),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(),

    // Output port
    .addrb(obj_idx),
    .dinb(0),
    .clkb(clk),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst),
    .regceb(1'b1),
    .doutb(obj)
  );
  
endmodule

`default_nettype wire
