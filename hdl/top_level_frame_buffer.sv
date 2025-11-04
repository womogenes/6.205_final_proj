`default_nettype none //  prevents system from inferring an undeclared logic (good practice)

`define FPATH(X) `"X`"

module top_level (
  input wire clk_100mhz, // crystal reference clock
  input wire [15:0] sw, // all 16 input slide switches

  input wire [3:0] btn, // all four momentary button switches
  output logic [15:0] led, // 16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, // rgb led
  output logic [2:0] rgb1, // rgb led

  // seven-segment outputs
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an,
  output logic [6:0] ss0_c,
  output logic [6:0] ss1_c,

  // HDMI, UART peripherals etc
  output logic [2:0] hdmi_tx_p, // hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, // hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n, // differential hdmi clock

  output logic [7:0] pmoda,

  //SDRAM (DDR3) ports
  inout wire [15:0]   ddr3_dq, //data input/output
  inout wire [1:0]    ddr3_dqs_n, //data input/output differential strobe (negative)
  inout wire [1:0]    ddr3_dqs_p, //data input/output differential strobe (positive)
  output wire [13:0]  ddr3_addr, //address
  output wire [2:0]   ddr3_ba, //bank address
  output wire         ddr3_ras_n, //row active strobe
  output wire         ddr3_cas_n, //column active strobe
  output wire         ddr3_we_n, //write enable
  output wire         ddr3_reset_n, //reset (active low!!!)
  output wire         ddr3_clk_p, //general differential clock (p)
  output wire         ddr3_clk_n, //general differential clock (n)
  output wire         ddr3_clke, //clock enable
  output wire [1:0]   ddr3_dm, //data mask
  output wire         ddr3_odt //on-die termination (helps impedance match)
);
  // shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  // buffered clock signal (we need this apparently)
  logic clk_100mhz_buffered;
 
  // have btn[0] control system reset
  logic sys_rst;
  assign sys_rst = btn[0]; // reset is btn[0]

  logic sys_rst_rtx;
  assign sys_rst_rtx = sys_rst;
  logic sys_rst_pixel;
  assign sys_rst_pixel = sys_rst;
  logic sys_rst_controller;
  assign sys_rst_controller = sys_rst;
 
  logic clk_pixel, clk_5x, clk_rtx; // clock lines
  logic locked; // locked signal (we'll leave unused but still hook it up)
  assign clk_rtx = clk_100mhz_buffered;
 
  logic [10:0] h_count_hdmi; // h_count of system!
  logic [9:0] v_count_hdmi; // v_count of system!

  logic h_sync; // horizontal sync signal
  logic v_sync; // vertical sync signal
  logic active_draw_hdmi; // ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; // one cycle active indicator of new frame of info!
  logic [5:0] frame_count; // 0 to 59 then rollover frame counter
 
  // written by you previously! (make sure you include in your hdl)
  // default instantiation so making signals for 720p
  video_sig_gen mvg(
    .pixel_clk(clk_pixel),
    .rst(sys_rst),
    .h_count(h_count_hdmi),
    .v_count(v_count_hdmi),
    .v_sync(v_sync),
    .h_sync(h_sync),
    .active_draw(active_draw_hdmi),
    .new_frame(new_frame),
    .frame_count(frame_count)
  );

  logic [7:0] red, green, blue; // red green and blue pixel values for output

  // FAKE RTX ENGINE
  logic [10:0] rtx_h_count;
  logic [10:0] rtx_skipped_counter;
  logic [9:0] rtx_v_count;
  logic [7:0] frame_count_rtx;
  logic [2:0][7:0] rendered_color_rtx;
  logic [15:0] rtx_pixel;
  logic [3:0] wait_counter_rtx;
  logic [2:0] rtx_skip_counter;
  logic rtx_valid;
  assign rtx_h_count = rtx_skipped_counter | rtx_skip_counter;

  always_ff @(posedge clk_rtx) begin
    if (sys_rst || btn[1]) begin
      rtx_skipped_counter <= 0;
      rtx_skip_counter <= 0;
      rtx_v_count <= 0;
      frame_count_rtx <= 0;
    end else begin
      
      wait_counter_rtx <= wait_counter_rtx + 1;

      if (wait_counter_rtx == 0) begin
        if (rtx_skipped_counter == 1272) begin
          rtx_skipped_counter <= 0;
          if (rtx_skip_counter == 7) begin
            rtx_skip_counter <= 0;
            if (rtx_v_count == 719) begin
              rtx_v_count <= 0;
              frame_count_rtx <= frame_count_rtx + 1;
            end else begin
              rtx_v_count <= rtx_v_count + 1;
            end
          end else begin
            rtx_skip_counter <= rtx_skip_counter + 1;
          end
        end else begin
          rtx_skipped_counter <= rtx_skipped_counter + 8;
        end
      end
    end
  end
  always_comb begin
    // red channel moves up and down linearly
    // if (frame_count_rtx[7] == 1'b0) begin
    //   rendered_color_rtx[2] = frame_count_rtx[6:0] << 1;
    // end else begin
    //   rendered_color_rtx[2] = 8'd255 - (frame_count_rtx[6:0] << 1);
    // end
    rtx_valid = wait_counter_rtx == 0;
    rendered_color_rtx[0] = 8'hff;//frame_count_rtx < rtx_v_count + rtx_h_count ? 255 : 0;
    // rendered_color_rtx[1] = 8'hff;
    // rendered_color_rtx[2] = 8'hff;

    // green channel is pwm divided by 8 width-wise
    rendered_color_rtx[1] = frame_count_rtx[2:0] > rtx_h_count[7:5] ? 255 : 0;

    // blue channel is pwn divided on a longer period
    rendered_color_rtx[2] = frame_count_rtx[5:3] > rtx_v_count[6:4] ? 255 : 0;
    rtx_pixel = {rendered_color_rtx[2][7:3], rendered_color_rtx[1][7:2], rendered_color_rtx[0][7:3]};

  end

  // ==== SEVEN SEGMENT DISPLAY =======
  seven_segment_controller(
    .clk(clk_100mhz_buffered),
    .rst(sys_rst),
    .val({frame_count_rtx, rendered_color_rtx}),//{blue, green, red}}),
    .cat(ss0_c),
    .an({ ss0_an, ss1_an })
  );
  assign ss1_c = ss0_c;

  logic [23:0] frame_buff_bram;
  frame_buffer #(
    .SIZE_H(320),
    .SIZE_V(180),
    .COLOR_WIDTH(12),
    .EXP_RATIO(8)
  ) frame_render (
    .rst(sys_rst),

    .clk_rtx(clk_rtx),

    .pixel_h(rtx_h_count >> 2),
    .pixel_v(rtx_v_count >> 2),
    .new_color(rendered_color_rtx),
    .new_color_valid(rtx_valid),

    .clk_hdmi(clk_pixel),

    .active_draw_hdmi(active_draw_hdmi),
    .h_count_hdmi(h_count_hdmi >> 2),
    .v_count_hdmi(v_count_hdmi >> 2),

    .pixel_out_color(frame_buff_bram),
    .pixel_out_valid(), //nothing for now
    .pixel_out_h_count(), //nothing for now
    .pixel_out_v_count() //nothing for now
  );


  logic clk_camera_locked;
  logic clk_pixel_locked;

  // clocking wizards to generate the clock speeds we need for our different domains
  // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
  cw_hdmi_clk_wiz wizard_hdmi(
      .sysclk(clk_100mhz_buffered),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x),
      .reset(0),
      .locked()
  );

  logic clk_controller;
  logic clk_ddr3;
  logic i_ref_clk;
  logic clk_ddr3_90;
  logic clk_camera;

  logic lab06_clk_locked;

  lab06_clk_wiz lcw(
      .reset(btn[0]),
      .clk_in1(clk_100mhz),
      .clk_camera(clk_camera),
      .clk_xc(0),
      .clk_passthrough(clk_100mhz_buffered),
      .clk_controller(clk_controller),
      .clk_ddr3(clk_ddr3),
      .clk_ddr3_90(clk_ddr3_90),
      .locked(lab06_clk_locked)
  );
  assign i_ref_clk = clk_camera;

  (* mark_debug = "true" *) wire ddr3_clk_locked;

  assign ddr3_clk_locked = lab06_clk_locked;
  // the high_definition_frame_buffer module does all of the
  // "top-level wiring" for the FIFOs, the stacker and unstacker
  // traffic generator, and the IP memory controller.
  // it needs:
  // 1. rtx data input, to write to the frame buffer
  // 2. output connection to the HDMI output
  // 3. the wires that connect to our DRAM chip
  logic [15:0] frame_buff_dram;
  high_definition_frame_buffer highdef_fb(
    // Input data from rtx/pixel reconstructor
    .clk_rtx      (clk_rtx),
    .sys_rst_rtx  (sys_rst_rtx),
    .rtx_valid    (rtx_valid),
    .rtx_pixel    (rtx_pixel),
    .rtx_h_count  (rtx_h_count[10:0]),
    .rtx_v_count  (rtx_v_count[9:0]),
    .rtx_overwrite(frame_count_rtx == 0),//frame_count[2:0] == 0),
    
    // Output data to HDMI display pipeline
    .clk_pixel       (clk_pixel),
    .sys_rst_pixel   (sys_rst_pixel),
    .active_draw_hdmi(active_draw_hdmi),
    .h_count_hdmi    (h_count_hdmi[10:0]),
    .v_count_hdmi    (v_count_hdmi[9:0]),
    .frame_buff_dram (frame_buff_dram[15:0]),

    // Clock/reset signals for UberDDR3 controller
    .clk_controller  (clk_controller),
    .clk_ddr3        (clk_ddr3),
    .clk_ddr3_90     (clk_ddr3_90),
    .i_ref_clk       (i_ref_clk),
    .i_rst           (sys_rst_controller),
    .ddr3_clk_locked (ddr3_clk_locked),

    .debug(pmoda[5:0]),

    // Bus wires to connect FPGA to SDRAM chip
    .ddr3_dq         (ddr3_dq[15:0]),
    .ddr3_dqs_n      (ddr3_dqs_n[1:0]),
    .ddr3_dqs_p      (ddr3_dqs_p[1:0]),
    .ddr3_addr       (ddr3_addr[13:0]),
    .ddr3_ba         (ddr3_ba[2:0]),
    .ddr3_ras_n      (ddr3_ras_n),
    .ddr3_cas_n      (ddr3_cas_n),
    .ddr3_we_n       (ddr3_we_n),
    .ddr3_reset_n    (ddr3_reset_n),
    .ddr3_clk_p      (ddr3_clk_p),
    .ddr3_clk_n      (ddr3_clk_n),
    .ddr3_clke       (ddr3_clke),
    .ddr3_dm         (ddr3_dm[1:0]),
    .ddr3_odt        (ddr3_odt)
  );

  always_comb begin
    if (sw[0]) begin
      red = {frame_buff_dram[4:0], 3'b0};
      green = {frame_buff_dram[10:5], 2'b0};
      blue = {frame_buff_dram[15:11], 3'b0};
    end else begin
      red = frame_buff_bram[7:0];
      green = frame_buff_bram[15:8];
      blue = frame_buff_bram[23:16];
    end
  end

  logic v_sync_buffered;
  logic h_sync_buffered;
  logic active_draw_buffered;
  pipeline #(
    .WIDTH(3),
    .DEPTH(2)
  ) vid_control_buffer (
    .clk(clk_pixel),
    .in({v_sync, h_sync, active_draw_hdmi}),
    .out({v_sync_buffered, h_sync_buffered, active_draw_buffered})
  );
 
  logic [9:0] tmds_10b [0:2]; // output of each TMDS encoder!
  logic tmds_signal [2:0]; // output of each TMDS serializer!
 
  tmds_encoder tmds_blue(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(blue),
    .control({ v_sync_buffered, h_sync_buffered }),  //  control signals
    .video_enable(active_draw_buffered),
    .tmds(tmds_10b[0])
  );

  tmds_encoder tmds_green(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(green),
    .control(2'b0),
    .video_enable(active_draw_buffered),
    .tmds(tmds_10b[1]));
 
  tmds_encoder tmds_red(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(red),
    .control(2'b0),
    .video_enable(active_draw_buffered),
    .tmds(tmds_10b[2]));
 
  // three tmds_serializers (blue, green, red):
  tmds_serializer blue_ser(
    .clk_pixel(clk_pixel),
    .clk_5x(clk_5x),
    .rst(sys_rst),
    .tmds_in(tmds_10b[0]),
    .tmds_out(tmds_signal[0]));

  tmds_serializer green_ser(
    .clk_pixel(clk_pixel),
    .clk_5x(clk_5x),
    .rst(sys_rst),
    .tmds_in(tmds_10b[1]),
    .tmds_out(tmds_signal[1]));

  tmds_serializer red_ser(
    .clk_pixel(clk_pixel),
    .clk_5x(clk_5x),
    .rst(sys_rst),
    .tmds_in(tmds_10b[2]),
    .tmds_out(tmds_signal[2]));

  // assign led[15] = highdef_fb.memrequest_busy;
  // assign led[14] = highdef_fb.memrequest_complete;
  // assign led[13] = highdef_fb.memrequest_resp_data[4];
  // assign led[12] = highdef_fb.memrequest_en;
  // assign led[11] = highdef_fb.memrequest_write_enable;
  // assign led[10] = highdef_fb.memrequest_addr[0];
  // assign led[9] = highdef_fb.display_memclk_axis_tvalid;
  // assign led[8] = highdef_fb.display_memclk_axis_tready;
  // assign led[7] = highdef_fb.camera_memclk_axis_tvalid;
  // assign led[6] = highdef_fb.camera_memclk_axis_tready;
 
  // output buffers generating differential signals:
  // three for the r,g,b signals and one that is at the pixel clock rate
  // the HDMI receivers use recover logic coupled with the control signals asserted
  // during blanking and sync periods to synchronize their faster bit clocks off
  // of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  // the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));
 
endmodule //  top_level
`default_nettype wire
