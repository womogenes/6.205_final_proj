// Multiplication for floating point
// 1-cycle delay (latched at output)

module fp_mul (
  input wire clk,
  input wire rst,
  input fp a,
  input fp b,

  output fp prod
);

  logic [FP_EXP_BITS-1:0] exp_a, exp_b;
  logic sign_a, sign_b;
  logic [FP_MANT_BITS-1:0] mant_a, mant_b;
  logic [FP_MANT_BITS:0] frac_a, frac_b;

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
  logic [FP_EXP_BITS:0] exp_prod;
  logic [(2*FP_MANT_BITS)+1:0] frac_prod;

  logic overflow;
  
  assign sign_prod = sign_a ^ sign_b;

  logic is_zero;
  assign is_zero = (exp_a == 0 && mant_a == 0) || (exp_b == 0 && mant_b == 0);

  always_comb begin
    overflow = 0;
    exp_prod = 0;
    frac_prod = 0;
    // Handle the zero cases
    if (is_zero) begin
      exp_prod = 0;
      frac_prod = 0;
    end else begin
      frac_prod = frac_a * frac_b;
      overflow = frac_prod[(2*FP_MANT_BITS)+1];
      exp_prod = exp_a + exp_b + overflow;
      // NOTE: we don't need this if all our numbers are in range
      // so small basically zero
      // if (exp_prod < 63) begin
      //   exp_prod = 0;
      //   frac_prod = 0;
      // end else if (exp_prod > 190) begin
      //   exp_prod = -1;
      //   frac_prod = 0;
      // end else begin
        exp_prod = exp_prod - FP_EXP_OFFSET;
      // end
    end
  end

  always_ff @(posedge clk) begin
    prod <= {
      is_zero ? 1'b0 : sign_prod,
      exp_prod[FP_EXP_BITS-1:0],
      overflow ?
        frac_prod[(2*FP_MANT_BITS):(FP_MANT_BITS+1)] :
        frac_prod[(2*FP_MANT_BITS)-1:FP_MANT_BITS]
    };
  end
endmodule
