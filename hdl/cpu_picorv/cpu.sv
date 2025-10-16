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
  localparam integer FB_ADDR = 'hC00;
  localparam integer MEM_SIZE = (1<<12);  // 12-bit address space
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
  logic [31:0] mask;                // 31-bit upsampled mask

  // Memory outputs (CPU mem inputs)
  logic cpu_mem_ready;
  logic [2:0] cpu_mem_cycle;        // keep track of which byte we're reading/writing
  logic [31:0] cpu_mem_rdata;

  // Memory (for our own use)
  logic [ADDR_WIDTH-1:0] addra;
  logic [31:0] douta;
  logic [31:0] dina;
  logic wea;                        // write enable (port a)

  always_comb begin
    cpu_mem_ready = (cpu_mem_wstrb == 4'b0000) ?
      (cpu_mem_cycle == 3) :
      (cpu_mem_cycle == 4);
    cpu_mem_rdata = douta;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      cpu_mem_cycle <= 0;
      wea <= 1'b0;
      addra <= 0;
      
    end else begin
      if (cpu_mem_valid) begin
        /* States:
          0: prep request word
          1: wait (requesting word)
          2: wait
          3: receive word
        */

        case (cpu_mem_wstrb)
          // Read
          4'b0000: begin
            case (cpu_mem_cycle)
              0: begin
                addra <= cpu_mem_addr >> 2; // word address
                wea <= 1'b0;
              end
            endcase

            // Go to next read cycle
            cpu_mem_cycle <= (cpu_mem_cycle == 3) ? 0 : cpu_mem_cycle + 1;
          end
          
          // Write
          /* States:
            0: prep request word
            1: wait (requesting word)
            2: wait
            3: receive word, compute next word and request write
            4: done (reset wea to 0)
          */
          default: begin
            case (cpu_mem_cycle)
              0: begin
                addra <= cpu_mem_addr >> 2;
                wea <= 1'b0;
              end
              1: begin end
              2: begin end
              3: begin
                mask = {
                  {8{cpu_mem_wstrb[3]}},
                  {8{cpu_mem_wstrb[2]}},
                  {8{cpu_mem_wstrb[1]}},
                  {8{cpu_mem_wstrb[0]}}
                };
                dina <= (douta & (~mask)) | (cpu_mem_wdata & mask);
                wea <= 1'b1;
              end
              4: begin
                wea <= 1'b0;
              end
            endcase

            // Go to next read cycle
            cpu_mem_cycle <= (cpu_mem_cycle == 4) ? 0 : cpu_mem_cycle + 1;
          end
        endcase
      end
    end
  end

  // CPU
  picorv32 #(
    .REGS_INIT_ZERO(1),
    // 21-bit address space
    .STACKADDR(32'h1fffc),
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
    .RAM_WIDTH(32),
    .RAM_DEPTH(MEM_SIZE), // arbitrary memory width for now (21 bit address space)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
    .INIT_FILE(INIT_FILE)
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
    .doutb(pixel[7:0])
  );
  // ====================

endmodule

`default_nettype wire
