`default_nettype none
module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20,
  parameter FPS = 60)
(

  input wire pixel_clk,
  input wire rst,
  output logic [$clog2(TOTAL_PIXELS)-1:0] h_count,
  output logic [$clog2(TOTAL_LINES)-1:0] v_count,
  output logic v_sync, //vertical sync out
  output logic h_sync, //horizontal sync out
  output logic active_draw,
  output logic new_frame, //single cycle enable signal
  output logic [5:0] frame_count //frame
);

  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;

  always_ff @(posedge pixel_clk) begin
    if (rst) begin
      // If reset, kill everything
      h_count <= 0;
      v_count <= 0;
      frame_count <= 0;
    end else begin
      if (h_count == TOTAL_PIXELS - 1) begin
        // If at end of line, roll over
        v_count <= v_count == TOTAL_LINES - 1 ? 0 : v_count + 1;
        h_count <= 0;
      end else begin
        h_count <= h_count + 1;
      end

      // Increment frame count
      if (new_frame) begin
        frame_count <= frame_count + new_frame;
      end
    end
  end

  // Combinational logic to determine output signals
  always_comb begin
    active_draw = (h_count < ACTIVE_H_PIXELS) && (v_count < ACTIVE_LINES);
    new_frame = (h_count == ACTIVE_H_PIXELS) && (v_count == ACTIVE_LINES - 1);
    h_sync = (
      h_count >= ACTIVE_H_PIXELS + H_FRONT_PORCH &&
      h_count < ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH
    );
    v_sync = (
      v_count >= ACTIVE_LINES + V_FRONT_PORCH &&
      v_count < ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH
    );
  end

endmodule

`default_nettype wire
