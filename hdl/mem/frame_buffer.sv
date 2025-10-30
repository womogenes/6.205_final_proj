`default_nettype none
module frame_buffer #(
  parameter SIZE_H = 1280,
  parameter SIZE_V = 720,
  parameter COLOR_WIDTH = 8,
  parameter EXP_RATIO = 6
) (
  input wire rst,

  input wire clk_rtx,

  input wire [10:0] pixel_h,
  input wire [9:0] pixel_v,
  input wire [2:0][7:0] new_color,
  input wire new_color_valid,

  input wire clk_hdmi,

  input wire active_draw_hdmi,
  input wire [10:0] h_count_hdmi,
  input wire [9:0] v_count_hdmi,

  output logic [2:0][7:0] pixel_out_color,
  output logic pixel_out_valid,
  output logic [10:0] pixel_out_h_count,
  output logic [9:0] pixel_out_v_count
);

  localparam integer EXP_MULTIPLIER = (2 ** EXP_RATIO) - 1;
    
  logic [20:0] addr_rtx;
  assign addr_rtx = pixel_h + pixel_v * SIZE_H;

  logic [20:0] addr_rtx_saved;
  always_ff @(posedge clk_rtx) begin
    if (rst) begin
      addr_rtx_saved <= 0;
    end else if (new_color_valid) begin
      addr_rtx_saved <= addr_rtx;
    end
  end

  logic [20:0] addr_hdmi;
  assign addr_hdmi = h_count_hdmi + v_count_hdmi * SIZE_H;

  logic [2:0][COLOR_WIDTH - 1:0] fetched_color;

  logic [2:0][7:0] new_color_buffered;
  logic new_color_valid_buffered;

  pipeline #(
    .WIDTH(25),
    .DEPTH(2)
  ) new_color_buffer (
    .clk(clk_rtx),
    .in({new_color_valid, new_color}),
    .out({new_color_valid_buffered, new_color_buffered})
  );

  logic [20:0] addr_rtx_used;
  assign addr_rtx_used = new_color_valid_buffered ? addr_rtx_saved : addr_rtx;

  logic [2:0][EXP_RATIO + COLOR_WIDTH - 1:0] scaled_color;
  logic [2:0][EXP_RATIO + COLOR_WIDTH - 1:0] added_color;
  logic [2:0][COLOR_WIDTH - 1:0] averaged_color;

  always_comb begin
    for (integer c = 0; c < 3; c = c + 1) begin
      scaled_color[c] = fetched_color[c] * EXP_MULTIPLIER;
      added_color[c] = scaled_color[c] + (new_color_buffered[c] << (COLOR_WIDTH - 8));
      // round instead of truncate
      // if (added_color[c][EXP_RATIO - 1:0] < (1 << EXP_RATIO)) begin
        averaged_color[c] = added_color[c] >> EXP_RATIO;
      // end else begin
      //   averaged_color[c] = (added_color >> (8 + EXP_RATIO - COLOR_WIDTH)) + 1;
      // end
    end
  end

  logic [2:0][COLOR_WIDTH - 1:0] fetched_out_color;
  assign pixel_out_color = {
    fetched_out_color[2][COLOR_WIDTH - 1: COLOR_WIDTH - 8],
    fetched_out_color[1][COLOR_WIDTH - 1: COLOR_WIDTH - 8],
    fetched_out_color[0][COLOR_WIDTH - 1: COLOR_WIDTH - 8]
    };

  // Port A corresponds to writing to the frame buffer
  // Port B corresponds to HDMI reading from the frame buffer
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(COLOR_WIDTH * 3),
    .RAM_DEPTH(SIZE_H * SIZE_V),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
  ) fb_bram (
    .addra(addr_rtx_used),  // Port A address bus, width determined from RAM_DEPTH
    .addrb(addr_hdmi),  // Port B address bus, width determined from RAM_DEPTH
    .dina(averaged_color),           // Port A RAM input data
    .dinb(0),           // Port B RAM input data
    .clka(clk_rtx),                           // Port A clock
    .clkb(clk_hdmi),                           // Port B clock
    .wea(new_color_valid_buffered),                            // Port A write enable
    .web(1'b0),                            // Port B write enable
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),                           // Port A output reset (does not affect memory contents)
    .rstb(rst),                           // Port B output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .regceb(1'b1),                         // Port B output register enable
    .douta(fetched_color),         // Port A RAM output data
    .doutb(fetched_out_color)          // Port B RAM output data
  );

  pipeline #(
    .WIDTH(22),
    .DEPTH(2)
  ) hdmi_info_buffer (
    .clk(clk_hdmi),
    .in({active_draw_hdmi, h_count_hdmi, v_count_hdmi}),
    .out({pixel_out_valid, pixel_out_h_count, pixel_out_v_count})
  );
endmodule

`default_nettype wire