`timescale 1ns / 1ps
`default_nettype none
 
module tmds_encoder(
  input wire clk,
  input wire rst,
  input wire [7:0] video_data, // video data (red, green or blue)
  input wire [1:0] control,    //for blue set to {vs,hs}, else will be 0
  input wire video_enable,     //choose between control (0) or video (1)
  output logic [9:0] tmds
);
  logic [8:0] q_m;

  tm_choice mtm(
    .d(video_data),
    .q_m(q_m)
  );

  logic [4:0] n_ones;
  logic [4:0] n_zeros;
  logic [4:0] cnt;     // running tally of ones/zeros

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
      tmds <= 0;

    end else if (~video_enable) begin
      cnt <= 0;

      case (control)
        2'b00: tmds <= 10'b1101010100;
        2'b01: tmds <= 10'b0010101011;
        2'b10: tmds <= 10'b0101010100;
        2'b11: tmds <= 10'b1010101011;
      endcase

    end else begin
      n_ones = 0;
      for (integer i = 0; i < 8; i = i+1) begin
        n_ones = n_ones + q_m[i];
      end
      n_zeros = 8 - n_ones;

      if (cnt == 0 || n_ones == 4) begin
        // equal amount, tie-break ??
        tmds[9] <= ~q_m[8];
        tmds[8] <= q_m[8];
        tmds[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];

        if (q_m[8] == 0) begin
          cnt <= cnt + (n_zeros - n_ones);
        end else begin
          cnt <= cnt + (n_ones - n_zeros);
        end

      end else begin
        // balance out ones and zeros
        if ((~cnt[4] && n_ones > n_zeros) || (cnt[4] && n_zeros > n_ones)) begin
          tmds[9] <= 1'b1;
          tmds[8] <= q_m[8];
          tmds[7:0] <= ~q_m[7:0];
          cnt <= cnt + ((q_m[8] & 1) << 1) + (n_zeros - n_ones);
        end else begin
          tmds[9] <= 1'b0;
          tmds[8] <= q_m[8];
          tmds[7:0] <= q_m[7:0];
          cnt <= cnt - ((~q_m[8] & 1) << 1) + (n_ones - n_zeros);
        end
      end
    end
  end
endmodule
 
`default_nettype wire
