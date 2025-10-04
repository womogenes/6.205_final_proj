`default_nettype none

// alu_func comes from proc_types.sv

typedef enum { ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA } alu_func;

// purely combinational ALU
module alu (
  input wire [31:0] a,
  input wire [31:0] b,
  input alu_func func,
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
