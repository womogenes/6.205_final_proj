`default_nettype none


// fake camera to replace real camera inputs, creating a 1280x720 test pattern
// in the DVP format.
module fake_camera(
  input wire clk,
  input wire rst,
  output logic camera_hsync,
  output logic camera_vsync,
  output logic [7:0] camera_data,
  output logic camera_pclk
);

  localparam SCENE_WIDTH     = 1280;
  localparam SCENE_HEIGHT    = 720;
  localparam HSYNC_LENGTH    = 80;
  localparam VSYNC_LENGTH    = 4;

  logic pclk_counter;

  logic [$clog2(SCENE_WIDTH+HSYNC_LENGTH)+1:0] hcount_doubled;
  logic [$clog2(SCENE_WIDTH+HSYNC_LENGTH):0]   hcount;

  assign hcount = hcount_doubled >> 1;
  
  logic [$clog2(SCENE_HEIGHT+VSYNC_LENGTH):0] vcount;

  assign camera_hsync = (hcount_doubled < SCENE_WIDTH*2);
  assign camera_vsync = (vcount < SCENE_HEIGHT);

  logic [7:0] frame_count;


  logic [7:0] red, green, blue;
  always_comb begin
    // define rgb based on hcount, vcount, etc
    // CHANGE ME TO MAKE NEW TEST PATTERNS! you can use
    // hcount/vcount/frame_counter to determine any new RGB patterns
    // maybe if testing center-of-mass, make a pink square that moves around!
    red   = hcount[7:0];
    green = vcount[7:0];
    blue = hcount[7:0]+vcount[7:0]+frame_count;

    // define camera_data based on the rgb values
    if (hcount_doubled[0]) begin
      camera_data = {green[4:2],blue[7:3]};
    end else begin
      camera_data = {red[7:3], green[7:5]};
    end
  end
  
  always_ff @(posedge clk) begin
    if (rst) begin
      vcount <= '0;
      pclk_counter <= 1'b0;
      hcount_doubled <= '0;
      camera_pclk <= 1'b0;
      frame_count <= '0;
    end else begin

      pclk_counter <= ~pclk_counter;
      if (pclk_counter) begin
        camera_pclk <= ~camera_pclk;

        if (camera_pclk == 1'b1) begin // falling edge, update data
          if (hcount_doubled >= (SCENE_WIDTH+HSYNC_LENGTH)*2) begin
            hcount_doubled <= 0;
            
            if (vcount >= SCENE_HEIGHT+VSYNC_LENGTH) begin
              vcount <= 0;
	      frame_count <= frame_count + 1;
            end else begin
              vcount <= vcount + 1;
            end
            
          end else begin
            hcount_doubled <= hcount_doubled + 1;
          end
        end
      end

    end

  end
endmodule

`default_nettype wire
