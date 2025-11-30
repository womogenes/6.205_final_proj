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

  // UART
  input wire uart_rxd,

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

  assign rendered_color_rtx = {
    {rtx_pixel[15:11], 3'b000},
    {rtx_pixel[10:5], 2'b00},
    {rtx_pixel[4:0], 3'b000}
  };

  // Real rtx?
  // Keep it dead until memrequest_busy is false
  logic dram_ready;
  always_ff @(posedge clk_rtx) begin
    if (sys_rst) begin
      dram_ready <= 1'b0;
    end else begin
      dram_ready <= dram_ready | !highdef_fb.memrequest_busy;
    end
  end

  // ===== UART MEMFLASH =====
  logic uart_flash_active;
  logic [7:0] uart_flash_cmd;
  logic [FP_VEC3_BITS-1:0] uart_flash_cam_data;
  logic [$bits(object)-1:0] uart_flash_obj_data;
  logic [$clog2(MAX_NUM_OBJS)-1:0] uart_flash_num_objs_data;
  logic [7:0] uart_flash_max_bounces_data;
  logic uart_flash_wen;

  logic uart_rx_buf0, uart_rx_buf1;
  always_ff @(posedge clk_100mhz_buffered) begin
    uart_rx_buf0 <= uart_rxd;
    uart_rx_buf1 <= uart_rx_buf0;
  end

  logic uart_rx_valid;
  logic [7:0] uart_rx_byte;

  uart_receive #(100_000_000, 115_200) uart_receiver (
    .clk(clk_100mhz_buffered),
    .rst(sys_rst),
    .din(uart_rx_buf1),
    .dout_valid(uart_rx_valid),
    .dout(uart_rx_byte)
  );

  uart_memflash_rtx (
    .clk(clk_rtx),
    .rst(sys_rst),
    .uart_rx_valid(uart_rx_valid),
    .uart_rx_byte(uart_rx_byte),

    .flash_active(uart_flash_active),
    .flash_cmd(uart_flash_cmd),
    .flash_cam_data(uart_flash_cam_data),
    .flash_obj_data(uart_flash_obj_data),
    .flash_num_objs_data(uart_flash_num_objs_data),
    .flash_max_bounces_data(uart_flash_max_bounces_data),
    .flash_wen(uart_flash_wen)
  );

  assign led[15] = uart_flash_active;
  // =========================

  // rtx requires an external scene buffer
  logic [$clog2(MAX_NUM_OBJS)-1:0] num_objs;
  object scene_buf_obj;

  // Scene buffer object overwriting
  logic flash_obj_wen;
  logic [OBJ_IDX_WIDTH-1:0] flash_obj_idx;
  logic [$bits(object)-1:0] flash_obj_data;

  // Scene buffer uart flashing logic
  always_comb begin
    flash_obj_wen = uart_flash_wen && (~uart_flash_cmd[7]);
    flash_obj_idx = uart_flash_cmd[6:0];
    flash_obj_data = uart_flash_obj_data;
  end

  scene_buffer #(.INIT_FILE("scene_buffer.mem")) scene_buf (
    .clk(clk_rtx),
    .rst(sys_rst),
    .num_objs(num_objs),
    .obj(scene_buf_obj),

    // Reprogram scene buffer with UART
    .flash_obj_wen(flash_obj_wen),
    .flash_obj_idx(flash_obj_idx),
    .flash_obj_data(flash_obj_data)
  );

  // max bounces is dynamic now
  logic [7:0] max_bounces;

  // rtx requires external camera
  camera cam;
  always_ff @(posedge clk_rtx) begin
    // Initialize camera
    if (sys_rst) begin
      cam.origin <= 'h0;
      cam.forward <= {'h000000, 'h000000, FP_HALF_SCREEN_WIDTH};  // (0, 0, 1280/2)
      cam.right <= {FP_ONE, 'h000000, 'h000000};                  // (1, 0, 0)
      cam.up <= {'h000000, FP_ONE, 'h000000};                     // (0, 1, 0)

      // half-sensible defaults
      num_objs <= 16;
      max_bounces <= 3;

    end else if (uart_flash_wen) begin
      casez (uart_flash_cmd)
        8'b1????000: cam.origin <= uart_flash_cam_data;
        8'b1????001: cam.forward <= uart_flash_cam_data;
        8'b1????010: cam.right <= uart_flash_cam_data;
        8'b1????011: cam.up <= uart_flash_cam_data;
        8'b1????100: num_objs <= uart_flash_num_objs_data;
        8'b1????101: max_bounces <= uart_flash_max_bounces_data;
      endcase
    end
  end

  assign led[13:0] = num_objs;

  rtx my_rtx(
    .clk(clk_rtx),
    .rst(sys_rst | !dram_ready),
    .cam(cam),

    .rtx_pixel(rtx_pixel),
    .pixel_h(rtx_h_count),
    .pixel_v(rtx_v_count),
    .ray_done(rtx_valid),

    .max_bounces(max_bounces),

    .num_objs(num_objs),
    .obj(scene_buf_obj)
  );

  // Latch overwrite on top left pixel
  logic rtx_overwrite;
  logic scene_changed;
  always_ff @(posedge clk_rtx) begin
    if (rtx_h_count == 1279 && rtx_v_count == 719 && rtx_valid) begin
      // At start of new frame, latch overwrite for entire frame
      rtx_overwrite <= sw[1] | scene_changed | uart_flash_wen;
      scene_changed <= 1'b0;

    end else if (uart_flash_wen) begin
      // Set flag when camera update happens mid-frame
      scene_changed <= 1'b1;
    end
  end

  assign led[14] = rtx_overwrite;

  // ==== SEVEN SEGMENT DISPLAY =======
  seven_segment_controller(
    .clk(clk_100mhz_buffered),
    .rst(sys_rst),
    .val({frame_count_rtx, rendered_color_rtx}), //{blue, green, red}}),
    .cat(ss0_c),
    .an({ ss0_an, ss1_an })
  );
  assign ss1_c = ss0_c;

  // logic [23:0] frame_buff_bram;
  // frame_buffer #(
  //   .SIZE_H(320),
  //   .SIZE_V(180),
  //   .COLOR_WIDTH(12),
  //   .EXP_RATIO(8)
  // ) frame_render (
  //   .rst(sys_rst),

  //   .clk_rtx(clk_rtx),

  //   .pixel_h(rtx_h_count >> 2),
  //   .pixel_v(rtx_v_count >> 2),
  //   .new_color(rendered_color_rtx),
  //   .new_color_valid(rtx_valid),

  //   .clk_hdmi(clk_pixel),

  //   .active_draw_hdmi(active_draw_hdmi),
  //   .h_count_hdmi(h_count_hdmi >> 2),
  //   .v_count_hdmi(v_count_hdmi >> 2),

  //   .pixel_out_color(frame_buff_bram),
  //   .pixel_out_valid(), //nothing for now
  //   .pixel_out_h_count(), //nothing for now
  //   .pixel_out_v_count() //nothing for now
  // );

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
    .rtx_overwrite(rtx_overwrite),
    
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
    // always use dram; commented out bram
    // if (sw[0]) begin
      red = {frame_buff_dram[4:0], 3'b0};
      green = {frame_buff_dram[10:5], 2'b0};
      blue = {frame_buff_dram[15:11], 3'b0};
    // end else begin
    //   red = frame_buff_bram[7:0];
    //   green = frame_buff_bram[15:8];
    //   blue = frame_buff_bram[23:16];
    // end
  end

  logic v_sync_buffered;
  logic h_sync_buffered;
  logic active_draw_buffered;

  // NOTE: the pipeline was causing issues with right halfof screen
  //   turns out zero cycles is the correct delay
  // pipeline #(
  //   .WIDTH(3),
  //   .DEPTH(0)
  // ) vid_control_buffer (
  //   .clk(clk_pixel),
  //   .in({v_sync, h_sync, active_draw_hdmi}),
  //   .out({v_sync_buffered, h_sync_buffered, active_draw_buffered})
  // );
  assign v_sync_buffered = v_sync;
  assign h_sync_buffered = h_sync;
  assign active_draw_buffered = active_draw_hdmi;
 
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
