`default_nettype none //  prevents system from inferring an undeclared logic (good practice)

`define FPATH(X) `"X`"

module top_level_rtx (
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
  output logic hdmi_clk_p, hdmi_clk_n // differential hdmi clock
);
  // shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  // buffered clock signal (we need this apparently)
  wire clk_100mhz_buffered;
  IBUF clkin1_ibufg (
    .I(clk_100mhz),
    .O(clk_100mhz_buffered)
  );
 
  // have btn[0] control system reset
  logic sys_rst;
  assign sys_rst = btn[0]; // reset is btn[0]
 
  logic clk_pixel, clk_5x, clk_rtx; // clock lines
  logic locked; // locked signal (we'll leave unused but still hook it up)
  assign clk_rtx = clk_100mhz_buffered;
 
  // clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
    .reset(0),
    .locked(locked),
    .clk_ref(clk_100mhz_buffered),
    .clk_pixel(clk_pixel),
    .clk_tmds(clk_5x)
  );
 
  logic [10:0] h_count; // h_count of system!
  logic [9:0] v_count; // v_count of system!

  logic h_sync; // horizontal sync signal
  logic v_sync; // vertical sync signal
  logic active_draw; // ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; // one cycle active indicator of new frame of info!
  logic [5:0] frame_count; // 0 to 59 then rollover frame counter
 
  // written by you previously! (make sure you include in your hdl)
  // default instantiation so making signals for 720p
  video_sig_gen mvg(
    .pixel_clk(clk_pixel),
    .rst(sys_rst),
    .h_count(h_count),
    .v_count(v_count),
    .v_sync(v_sync),
    .h_sync(h_sync),
    .active_draw(active_draw),
    .new_frame(new_frame),
    .frame_count(frame_count)
  );

  logic [7:0] red, green, blue; // red green and blue pixel values for output

  // FAKE RTX ENGINE
  logic [10:0] pixel_h_rtx;
  logic [9:0] pixel_v_rtx;
  logic [7:0] frame_count_rtx;
  logic [2:0][7:0] rendered_color_rtx;
  logic [7:0] wait_counter_rtx;
  logic rendered_color_valid_rtx;

  always_ff @(posedge clk_rtx) begin
    if (sys_rst) begin
      pixel_h_rtx <= 0;
      pixel_v_rtx <= 0;
      frame_count_rtx <= 0;
    end else begin
      
      wait_counter_rtx <= wait_counter_rtx + 1;

      if (wait_counter_rtx == 0) begin
        if (pixel_h_rtx == 319) begin
          pixel_h_rtx <= 0;
          if (pixel_v_rtx == 179) begin
            pixel_v_rtx <= 0;
            frame_count_rtx <= frame_count_rtx + 1;
          end else begin
            pixel_v_rtx <= pixel_v_rtx + 1;
          end
        end else begin
          pixel_h_rtx <= pixel_h_rtx + 1;
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
    rendered_color_valid_rtx = wait_counter_rtx == 0;
    rendered_color_rtx[0] = 8'hff;
    // rendered_color_rtx[1] = 8'hff;
    // rendered_color_rtx[2] = 8'hff;

    // green channel is pwm divided by 8 width-wise
    rendered_color_rtx[1] = frame_count_rtx[2:0] > pixel_h_rtx[7:5] ? 255 : 0;

    // blue channel is pwn divided on a longer period
    rendered_color_rtx[2] = frame_count_rtx[7:5] > pixel_v_rtx[6:4] ? 255 : 0;

    // rendered_color_rtx[0] = 0;
    // rendered_color_rtx[1] = 64;
    // rendered_color_rtx[2] = 128;

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

  frame_buffer #(
    .SIZE_H(320),
    .SIZE_V(180),
    .COLOR_WIDTH(12),
    .EXP_RATIO(8)
  ) frame_render (
    .rst(sys_rst),

    .clk_rtx(clk_rtx),

    .pixel_h(pixel_h_rtx),
    .pixel_v(pixel_v_rtx),
    .new_color(rendered_color_rtx),
    .new_color_valid(rendered_color_valid_rtx),

    .clk_hdmi(clk_pixel),

    .active_draw_hdmi(active_draw),
    .h_count_hdmi(h_count >> 2),
    .v_count_hdmi(v_count >> 2),

    .pixel_out_color({blue, green, red}),
    .pixel_out_valid(), //nothing for now
    .pixel_out_h_count(), //nothing for now
    .pixel_out_v_count() //nothing for now
  );

  logic v_sync_buffered;
  logic h_sync_buffered;
  logic active_draw_buffered;
  pipeline #(
    .WIDTH(3),
    .DEPTH(2)
  ) vid_control_buffer (
    .clk(clk_pixel),
    .in({v_sync, h_sync, active_draw}),
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
