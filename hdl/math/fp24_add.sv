// Addition for 24-bit floating point

function automatic [4:0] clz17(input logic [16:0] x);
  logic [4:0] res;
  begin
    res = 17;
    for (integer i = 16; i >= 0; i = i - 1) begin : for_loop
      if (x[i]) begin
        res = 16 - i;
        disable for_loop;   // exit early
      end
    end
  end
  return res;
endfunction

module fp24_add (
  input wire clk,
  input wire rst,
  input wire [23:0] a,
  input wire [23:0] b,
  input wire is_sub,

  output logic [23:0] sum
);
  // Extract fields and swap if b > a
  logic swap;
  assign swap = b[22:16] > a[22:16];

  logic [6:0] exp_a, exp_b;
  logic sign_a, sign_b;
  logic [15:0] mant_a, mant_b;
  logic [17:0] frac_a, frac_b;

  assign exp_a = swap ? b[22:16] : a[22:16];
  assign exp_b = swap ? a[22:16] : b[22:16];

  assign sign_a = swap ? (b[23] ^ is_sub) : a[23];
  assign sign_b = swap ? a[23] : (b[23] ^ is_sub);
  
  assign mant_a = swap ? b[15:0] : a[15:0];
  assign mant_b = swap ? a[15:0] : b[15:0];

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
    // Handle the zero cases
    if (exp_a == 0 && frac_a == 0) sum = b;
    else if (exp_b == 0 && frac_b == 0) sum = a;

    else begin
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
  end
endmodule
