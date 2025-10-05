`default_nettype none

typedef enum logic [3:0] { ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA } AluFunc;

// purely combinational ALU
module alu (
  input wire [31:0] a,
  input wire [31:0] b,
  input AluFunc func,
  output logic [31:0] res
);
  always_comb begin
    case (func)
      ADD: res = a + b;
      SUB: res = a - b;
      AND: res = a & b;
      OR: res = a | b;
      XOR:  res = a ^ b;
      SLT: res = $signed(a) < $signed(b);
      SLTU: res = a < b;
      SLL: res = a << b;
      SRL: res = a >> b;
      SRA: res = $signed(a) >>> b;  // weird syntax but it works
    endcase;
  end
endmodule

`default_nettype wire
