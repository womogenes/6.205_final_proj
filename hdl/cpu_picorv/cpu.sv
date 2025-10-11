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
  output logic [7:0] pixel,
  output logic trap
);
  localparam integer FB_ADDR = 'h41000;
  localparam integer MEM_SIZE = 2048 * 1024;
  localparam integer ADDR_WIDTH = $clog2(MEM_SIZE);

  // Fixed at 320x180
  logic [ADDR_WIDTH-1:0] pixel_addr;
  always_comb begin
    pixel_addr = ((v_count_hdmi >> 2) * 320 + (h_count_hdmi >> 2)) + FB_ADDR;
  end

  // Memory state machine
  logic cpu_mem_valid;
  logic cpu_mem_instr;
  logic [31:0] cpu_mem_addr;
  logic [31:0] cpu_mem_wdata;
  logic [3:0] cpu_mem_wstrb;        // store mask

  // Memory outputs (CPU mem inputs)
  logic cpu_mem_ready;
  logic [2:0] cpu_mem_cycle;        // keep track of which byte we're reading/writing
  logic [31:0] cpu_mem_rdata;

  // Memory (for our own use)
  logic [ADDR_WIDTH-1:0] addra;
  logic [7:0] douta;
  logic [7:0] dina;
  logic wea;                        // write enable (port a)

  always_ff @(posedge clk) begin
    if (rst) begin
      cpu_mem_ready <= 1'b0;
      cpu_mem_rdata <= 32'b0;
      cpu_mem_cycle <= 0;
      wea <= 1'b0;
      addra <= 0;
      
    end else begin
      if (cpu_mem_valid) begin
        /* States:
          0: request byte 0
          1: request byte 1
          2: request byte 2, get byte 0
          3: request byte 3, get byte 1
          4: get byte 2
          5: get byte 3, prep data return
          6: reset
        */

        // TODO: make this more streamlined
        case (cpu_mem_wstrb)
          // Read
          4'b0000: begin
            case (cpu_mem_cycle)
              0: begin
                cpu_mem_rdata <= 0;
                addra <= cpu_mem_addr;
              end
              1: addra <= cpu_mem_addr + 1;
              2: begin
                addra <= cpu_mem_addr + 2;
              end
              3: begin
                addra <= cpu_mem_addr + 3;
                cpu_mem_rdata[7:0] <= douta;
              end
              4: begin
                cpu_mem_rdata[15:8] <= douta;
              end
              5: begin
                cpu_mem_rdata[23:16] <= douta;
              end
              6: begin
                cpu_mem_rdata[31:24] <= douta;
                cpu_mem_ready <= 1'b1;
              end
              7: begin
                cpu_mem_ready <= 1'b0;
              end
              default: cpu_mem_ready <= 1'b0;     // should never get hit
            endcase

            // Go to next read cycle
            cpu_mem_cycle <= (cpu_mem_cycle == 7) ? 0 : cpu_mem_cycle + 1;
          end
          
          // Write
          default: begin
            case (cpu_mem_cycle)
              0: begin
                addra <= cpu_mem_addr;
                dina <= cpu_mem_wdata[7:0];
                wea <= cpu_mem_wstrb[0];
                cpu_mem_ready <= 1'b0;
              end
              1: begin
                addra <= cpu_mem_addr + 1;
                dina <= cpu_mem_wdata[15:8];
                wea <= cpu_mem_wstrb[1];
              end
              2: begin
                addra <= cpu_mem_addr + 2;
                dina <= cpu_mem_wdata[23:16];
                wea <= cpu_mem_wstrb[2];
              end
              3: begin
                addra <= cpu_mem_addr + 3;
                dina <= cpu_mem_wdata[31:24];
                wea <= cpu_mem_wstrb[3];
              end
              4: begin
                wea <= 1'b0;
              end
              5: begin end
              6: begin
                cpu_mem_ready <= 1'b1;
              end
              7: begin
                cpu_mem_ready <= 1'b0;
              end
              default: begin
                cpu_mem_ready <= 1'b0;     // should never get hit
              end
            endcase

            // Go to next read cycle
            cpu_mem_cycle <= (cpu_mem_cycle == 7) ? 0 : cpu_mem_cycle + 1;
          end
        endcase

      end else begin
        cpu_mem_ready <= 1'b0;
      end
    end
  end

  // CPU
  picorv32 #(
    .REGS_INIT_ZERO(1),
    // 21-bit address space
    .STACKADDR(32'h1ffffc),
    .CATCH_MISALIGN(0)
  ) cpu (
    .clk(clk),
    .resetn(~rst),

    // Memory interface
    // Outputs
    .mem_valid(cpu_mem_valid),
    .mem_instr(cpu_mem_instr),
    .mem_addr(cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_wstrb(cpu_mem_wstrb),

    // Inputs
    .mem_ready(cpu_mem_ready),
    .mem_rdata(cpu_mem_rdata),

    // Trap?
    .trap(trap)
  );

  // Memory
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(MEM_SIZE), // arbitrary memory width for now (21 bit address space)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE("program.mem")
  ) main_mem (
    // CPU read/write
    .addra(addra),
    .clka(clk),
    .wea(wea),
    .dina(dina),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst),
    .douta(douta),
    
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
