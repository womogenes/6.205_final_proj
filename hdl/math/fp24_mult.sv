// Multiplication for 24-bit floating point

module fp24_mult (
  input wire clk,
  input wire rst,
  input wire [23:0] a,
  input wire [23:0] b,

  output logic [23:0] prod
);

  logic [6:0] exp_a, exp_b;
  logic sign_a, sign_b;
  logic [15:0] mant_a, mant_b;
  logic [16:0] frac_a, frac_b;

  assign exp_a = a[22:16];
  assign exp_b = b[22:16];

  assign sign_a = a[23];
  assign sign_b = b[23];
  
  assign mant_a = a[15:0];
  assign mant_b = b[15:0];

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
      prod = {sign_prod, exp_prod[6:0], overflow ? frac_prod[32:17] : frac_prod[31:16]};
    end
  end
endmodule
