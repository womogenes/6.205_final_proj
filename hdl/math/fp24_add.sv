// Hepler function: compare two fp24s
function automatic fp24 fp24_greater(fp24 a, fp24 b);
  logic greater;
  greater = (a.exp > b.exp) || (a.exp == b.exp && a.mant > b.mant);
  return greater;
endfunction

// Addition for 24-bit floating point
module fp24_add (
  input wire clk,
  input wire rst,
  input fp24 a,
  input fp24 b,
  input wire is_sub = 1'b0,

  output fp24 sum
);
  // Extract fields and swap if b > a
  logic swap;
  assign swap = ~fp24_greater(a, b);

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
  logic [16:0] frac_norm;
  logic [6:0] exp_norm;
  logic [4:0] shift;

  // PIPELINE REGISTERS
  logic sign_a_buf;
  logic [6:0] exp_a_buf;
  logic [17:0] frac_sum_buf;

  // Stage 1: compute exponent diff + shift
  always_comb begin
    // Align exponents
    exp_diff = exp_a - exp_b;
    frac_b_shift = frac_b >> exp_diff;
  end

  // Stage 1.5: save to registers
  always_ff @(posedge clk) begin
    // Add/subtract
    frac_sum_buf <= (sign_a == sign_b) ? (frac_a + frac_b_shift) : (frac_a - frac_b_shift);
    exp_a_buf <= exp_a;
    sign_a_buf <= sign_a;
  end

  // Stage 2: clz, assemble sum

  // Normalize result
  clz #(.WIDTH(17)) clz_shift (.x(frac_sum_buf[16:0]), .count(shift));

  always_comb begin
    if (frac_sum_buf[17]) begin
      // We overflowed!
      frac_norm = frac_sum_buf[17:1];
      exp_norm = exp_a_buf + 1;
      
    end else begin
      // Maybe underflowed, see `shift`
      frac_norm = frac_sum_buf[16:0] << shift;
      exp_norm = exp_a_buf - shift;
    end
  end

  // Stage 2 end: latch
  always_ff @(posedge clk) begin
    sum <= {sign_a_buf, exp_norm, frac_norm[15:0]};
  end
endmodule
