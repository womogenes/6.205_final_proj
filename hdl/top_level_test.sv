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
  output logic [6:0] ss1_c
);
  // shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;

  // have btn[0] control system reset
  logic sys_rst;
  assign sys_rst = btn[0]; // reset is btn[0]

  localparam integer WIDTH_A = 64;
  localparam integer WIDTH_B = 64;
  localparam integer BITS_DROPPED = 64;
  localparam integer OUTPUT_WIDTH = WIDTH_A + WIDTH_B - BITS_DROPPED;

  logic [15:0] sw_rev;
  logic [WIDTH_A - 1:0] a;
  logic [WIDTH_B - 1:0] b;

  always_comb begin
    for (integer i = 0; i < 16; i = i + 1) begin
      sw_rev[15 - i] = sw[i];
    end
    a = {sw_rev, sw, sw_rev, sw};
    b = {sw, sw_rev, sw, sw_rev};

  end




  logic [$clog2(OUTPUT_WIDTH) - 1:0] counter;
  always_ff @(posedge clk_100mhz) begin
    if (counter == OUTPUT_WIDTH - 1) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  

  logic [OUTPUT_WIDTH:0] dout_lazy;
  logic dout_valid_lazy;

  logic [OUTPUT_WIDTH:0] dout_hard;
  logic dout_valid_hard;

  

  lazy_multiplier #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_B(WIDTH_B),
    .BITS_DROPPED(BITS_DROPPED)
  ) lazy (
    .rst(sys_rst),
    .clk(clk_100mhz),

    .din_a(a),
    .din_b(b),
    .din_valid(btn[2]),

    .dout(dout_lazy),
    .dout_valid(dout_valid_lazy)
  );

  multiplier #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_B(WIDTH_B),
    .BITS_DROPPED(BITS_DROPPED)
  ) hard (
    .rst(sys_rst),
    .clk(clk_100mhz),

    .din_a(a),
    .din_b(b),
    .din_valid(btn[2]),

    .dout(dout_hard),
    .dout_valid(dout_valid_hard)
  );

  assign led[0] = dout_lazy[counter];
  assign led[1] = dout_hard[counter];
 
endmodule //  top_level
`default_nettype wire
