`timescale 1ns / 1ps
`default_nettype none

module prng8 (
  input wire clk,
  input wire rst,
  input wire [47:0] seed,
  output logic [7:0] rng
);
  logic [47:0] lfsr_reg;
  logic feedback_bit;

  assign rng = {lfsr_reg[47:44], lfsr_reg[27:24]};

  // Use ring oscillator in synthesis mode
  `ifdef SYNTHESIS
    logic ring_osc_bit;
    ring_osc_sampler ro_sampler(.clk(clk), .rst(rst), .rng_bit(ring_osc_bit));
    assign feedback_bit = lfsr_reg[47] ^ ring_osc_bit;
  `else
    assign feedback_bit = lfsr_reg[47];
  `endif

  always_ff @(posedge clk) begin
    if (rst)
      lfsr_reg <= seed; // Nonzero seed. Never all-zeros!
    else begin
      lfsr_reg[0]     <= feedback_bit;
      lfsr_reg[1]     <= lfsr_reg[0]  ^ feedback_bit;
      lfsr_reg[26]    <= lfsr_reg[25] ^ feedback_bit;
      lfsr_reg[27]    <= lfsr_reg[26] ^ feedback_bit;
      lfsr_reg[25:2]  <= lfsr_reg[24:1];
      lfsr_reg[47:28] <= lfsr_reg[46:27];
    end
  end
endmodule


`default_nettype wire
