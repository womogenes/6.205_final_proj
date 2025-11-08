// Random numbers using ring oscillator (yay Vivado)

`default_nettype none

module ring_osc_sampler #(
  parameter integer RO_COUNT = 4
) (
  input wire clk,
  input wire rst,
  output logic rng_bit
);
  wire [RO_COUNT-1:0] ro_bits_raw;

  genvar i;
  generate
    for (i = 0; i < RO_COUNT; i++) begin : ro_array
      // Ring oscillator wires
      wire n0, n1, n2;

      (* keep = "true", dont_touch = "true" *)
      LUT1 #(.INIT(2'b01)) inv0 (.I0(n0), .O(n1));
      (* keep = "true", dont_touch = "true" *)
      LUT1 #(.INIT(2'b01)) inv1 (.I0(n1), .O(n2));
      (* keep = "true", dont_touch = "true" *)
      LUT1 #(.INIT(2'b01)) inv2 (.I0(n2), .O(n0));

      assign ro_bits_raw[i] = n2;
    end
  endgenerate

  // Sychronizers (prevent metastability)
  logic [RO_COUNT-1:0] ro_bits_buf0, ro_bits_buf1;

  always_ff @(posedge clk) begin
    if (rst) begin
      ro_bits_buf0 <= 0;
      ro_bits_buf1 <= 0;
    end else begin
      ro_bits_buf0 <= ro_bits_raw;
      ro_bits_buf1 <= ro_bits_buf0;
    end
  end

  // XOR all ring oscillators together
  assign rng_bit = ^ro_bits_buf1;

endmodule

`default_nettype wire
