`default_nettype none

typedef enum logic [3:0] { ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA } AluFunc;

// purely combinational ALU
module alu (
  input wire [31:0] a,
  input wire [31:0] b,
  input AluFunc func,
  output logic [31:0] out
);
  always_comb begin
    case (func)
      ADD: out = a + b;
      SUB: out = a - b;
      AND: out = a & b;
      OR: out = a | b;
      XOR:  out = a ^ b;
      SLT: out = $signed(a) < $signed(b);
      SLTU: out = a < b;
      SLL: out = a << b[4:0];
      SRL: out = a >> b[4:0];
      SRA: out = $signed(a) >>> b[4:0];  // weird syntax but it works
    endcase;
  end
endmodule

`default_nettype wire
