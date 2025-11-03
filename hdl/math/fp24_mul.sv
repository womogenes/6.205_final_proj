// Multiplication for 24-bit floating point

module fp24_mul (
  // input wire clk,
  // input wire rst,
  input fp24 a,
  input fp24 b,

  output fp24 prod
);

  logic [6:0] exp_a, exp_b;
  logic sign_a, sign_b;
  logic [15:0] mant_a, mant_b;
  logic [16:0] frac_a, frac_b;

  assign exp_a = a.exp;
  assign exp_b = b.exp;

  assign sign_a = a.sign;
  assign sign_b = b.sign;
  
  assign mant_a = a.mant;
  assign mant_b = b.mant;

  // Add leading 1s
  assign frac_a = {1'b1, mant_a};
  assign frac_b = {1'b1, mant_b};

  // Outputs
  logic sign_prod;
  logic [7:0] exp_prod;
  logic [33:0] frac_prod;

  logic overflow;
  
  assign sign_prod = sign_a ^ sign_b;

  always_comb begin
    overflow = 0;
    exp_prod = 0;
    frac_prod = 0;
    // Handle the zero cases
    if ((exp_a == 0 && mant_a == 0) || 
    (exp_b == 0 && mant_b == 0)) begin
        exp_prod = 0;
        frac_prod = 0;
    end else begin
      frac_prod = frac_a * frac_b;
      overflow = frac_prod[33];
      exp_prod = exp_a + exp_b + overflow;
      // so small basically zero
      if (exp_prod < 63) begin
        exp_prod = 0;
        frac_prod = 0;
      end else if (exp_prod > 190) begin
        exp_prod = -1;
        frac_prod = 0;
      end else begin
        exp_prod = exp_prod - 63;
      end
    end
    prod = {sign_prod, exp_prod[6:0], overflow ? frac_prod[32:17] : frac_prod[31:16]};
  end
endmodule
