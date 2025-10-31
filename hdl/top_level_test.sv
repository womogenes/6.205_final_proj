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
  logic sys_rst;
  assign sys_rst = btn[0];

  logic [23:0] a;
  logic [23:0] b;

  assign a = {sw, sw[7:0]};
  assign b = {sw, sw[7:0]};

  logic [23:0] sum;

  fp24_add(
    .clk(clk_100mhz),
    .rst(sys_rst),
    .a(a),
    .b(b),
    .is_sub(btn[1]),
    .sum(sum)
  );

  assign {led, ss0_c, ss1_c[0]} = sum;

endmodule //  top_level
`default_nettype wire
