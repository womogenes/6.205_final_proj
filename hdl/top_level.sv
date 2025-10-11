`default_nettype none //  prevents system from inferring an undeclared logic (good practice)
 
module top_level (
  input wire clk_100mhz, // crystal reference clock
  input wire [15:0] sw, // all 16 input slide switches
  input wire [3:0] btn, // all four momentary button switches
  output logic [15:0] led, // 16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, // rgb led
  output logic [2:0] rgb1, // rgb led
  output logic [2:0] hdmi_tx_p, // hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, // hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n // differential hdmi clock
);
  assign led = sw; // to verify the switch values

  // shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;
 
  // have btn[0] control system reset
  logic sys_rst;
  assign sys_rst = btn[0]; // reset is btn[0]
  logic game_rst;
 
  logic clk_pixel, clk_5x; // clock lines
  logic locked; // locked signal (we'll leave unused but still hook it up)
 
  // clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
    .reset(0),
    .locked(locked),
    .clk_ref(clk_100mhz),
    .clk_pixel(clk_pixel),
    .clk_tmds(clk_5x));
 
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
    .frame_count(frame_count));
 
  logic [7:0] red, green, blue; // red green and blue pixel values for output
 
  // comment out in checkoff 1 once you know you have your video pipeline working:
  // these three colors should be the 2025 6.205 color on full screen .
  assign red = 8'hD4;
  assign green = 8'h6A;
  assign blue = 8'h4C;
 
  logic [9:0] tmds_10b [0:2]; // output of each TMDS encoder!
  logic tmds_signal [2:0]; // output of each TMDS serializer!
 
  // three tmds_encoders (blue, green, red)
  // MISSING two more tmds encoders (one for green and one for blue)
  // note green should have no control signal like red
  // the blue channel DOES carry the two sync signals:
  //   * control[0] = horizontal sync signal
  //   * control[1] = vertical sync signal
  tmds_encoder tmds_blue(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(blue),
    .control({ v_sync, h_sync }),  //  control signals
    .video_enable(active_draw),
    .tmds(tmds_10b[0]));

  tmds_encoder tmds_green(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(green),
    .control(2'b0),
    .video_enable(active_draw),
    .tmds(tmds_10b[1]));
 
  tmds_encoder tmds_red(
    .clk(clk_pixel),
    .rst(sys_rst),
    .video_data(red),
    .control(2'b0),
    .video_enable(active_draw),
    .tmds(tmds_10b[2]));
 
  // three tmds_serializers (blue, green, red):
  // MISSING: two more serializers for the green and blue tmds signals.
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
