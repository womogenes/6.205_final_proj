// Addition for 24-bit floating point

function automatic [4:0] clz17(input logic [16:0] x);
  integer i;
  begin
    for (i = 16; i >= 0; i = i - 1) begin
      if (x[i])
        return 16 - i; // return immediately
    end
    return 17; // all zeros
  end
endfunction

module fp24_add (
  input wire clk,
  input wire rst,
  input fp24 a,
  input fp24 b,
  input wire is_sub,

  output fp24 sum
);
  // Extract fields and swap if b > a
  logic swap;
  assign swap = (b.exp > a.exp) || (b.exp == a.exp && b.mant > a.mant);

  logic [6:0] exp_a, exp_b;
  logic sign_a, sign_b;
  logic [15:0] mant_a, mant_b;
  logic [17:0] frac_a, frac_b;

  assign exp_a = swap ? b.exp : a.exp;
  assign exp_b = swap ? a.exp : b.exp;

  assign sign_a = swap ? (b.sign ^ is_sub) : a.sign;
  assign sign_b = swap ? a.sign : (b.sign ^ is_sub);
  
  assign mant_a = swap ? b.mant : a.mant;
  assign mant_b = swap ? a.mant : b.mant;

  // Add leading 1s
  assign frac_a = {2'b01, mant_a};
  assign frac_b = {2'b01, mant_b};

  // Outputs
  logic [6:0] exp_diff;
  logic [17:0] frac_b_shift;
  logic [17:0] frac_sum;
  logic [16:0] frac_norm;
  logic [6:0] exp_norm;
  logic [4:0] shift;

  always_comb begin
    // Align exponents
    exp_diff = exp_a - exp_b;
    frac_b_shift = frac_b >> exp_diff;

    // Add/subtract
    frac_sum = (sign_a == sign_b) ? (frac_a + frac_b_shift) : (frac_a - frac_b_shift);

    // Normalize result
    shift = clz17(frac_sum[16:0]);

    if (frac_sum[17]) begin
      // We overflowed!
      frac_norm = frac_sum[17:1];
      exp_norm = exp_a + 1;
      
    end else begin
      // Maybe underflowed, see `shift`
      frac_norm = frac_sum[16:0] << shift;
      exp_norm = exp_a - shift;
    end

    sum = {sign_a, exp_norm, frac_norm[15:0]};
  end
endmodule
