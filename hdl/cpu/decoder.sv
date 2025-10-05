`default_nettype none

module decoder (
  input wire [31:0] inst,
  output DecodedInst dinst
);
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] dst, src1, src2;

  // extracted immediates
  logic [11:0] immB;
  logic [19:0] immU;
  logic [11:0] immI;
  logic [20:0] immJ;
  logic [11:0] immS;

  // fully sign-extended immediates
  logic [31:0] immB32, immU32, immI32, immJ32, immS32;

  always_comb begin
    opcode = inst[6:0];
    funct3 = inst[14:12];
    funct7 = inst[31:25];
    dst = inst[11:7];         // destination register
    src1 = inst[19:15];       // source register 1
    src2 = inst[24:20];       // source register 2

    // construct immediates first

    // sign-extended B-type imm (branch?)
    immB = { inst[31], inst[7], inst[30:25], inst[11:8] };
    immB32 = { {(32-12){immB[11]}}, immB };

    // sign-extended U-type imm (LUI and JAL)
    immU = inst[31:12];
    immU32 = { {(32-20){immU[19]}}, immU } << 12;

    // sign-extended I-type imm (any imm)
    immI = inst[31:20];
    immI32 = { {(32-12){immI[11]}}, immI };

    // sign-extended J-type imm (regular jumps)
    immJ = { inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };
    immJ32 = { {(32-21){immJ[20]}}, immJ };

    // sign-extended S-type imm (store)
    immS = { inst[31:25], inst[11:7] };
    immS32 = { {(32-12){immS[11]}}, immS };

    // set the decoded instruction
    case (opcode)
      // add upper immediate to PC
      op_AUIPC: begin
        dinst.itype = AUIPC;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;
        dinst.imm = immU32;
      end

      // load upper immediate to dst
      op_LUI: begin
        dinst.itype = LUI;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;
        dinst.imm = immU32;
      end

      // some immediate operation (e.g. andi, addi, etc.)
      op_OPIMM: begin
        dinst.itype = OPIMM;
        dinst.src1 = src1;
        dinst.imm = immI32;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;

        case (funct3)
          fn_ADD: dinst.alufunc = AND;
          fn_OR: dinst.alufunc = OR;
          fn_XOR: dinst.alufunc = XOR;
          fn_ADD: dinst.alufunc = ADD;
          fn_SLT: dinst.alufunc = SLT;
          fn_SLTU: dinst.alufunc = SLTU;
          fn_SLL: case (funct7)
            // check if valid SLLI instruction
            7'b0000000: dinst.alufunc = SLL;
            default: dinst.alufunc = Unsupported;
          endcase
          fn_SR: case (funct7)
            7'b0000000: dinst.alufunc = SRL;
            7'b0100000: dinst.alufunc = SRA;
            default: dinst.itype = Unsupported;
          endcase
          default: dinst.itype = Unsupported;
        endcase
      end

      // regular operations (e.g. add, sub, and, etc.)
      op_OP: begin
        dinst.itype = OP;
        dinst.src1 = src1;
        dinst.src2 = src2;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;

        case (funct3)
          fn_ADD: case (funct7)
            7'b0000000: dinst.alufunc = AND;
            default: dinst.itype = Unsupported;
          endcase
          fn_AND: case (funct7)
            7'b0000000: dinst.alufunc = AND;
            default: dinst.itype = Unsupported;
          endcase
          fn_OR: case (funct7)
            7'b0000000: dinst.alufunc = OR;
            default: dinst.itype = Unsupported;
          endcase
          fn_XOR: case (funct7)
            7'b0000000: dinst.alufunc = XOR;
            default: dinst.itype = Unsupported;
          endcase
          fn_SLT: case (funct7)
            7'b0000000: dinst.alufunc = SLT;
            default: dinst.itype = Unsupported;
          endcase
          fn_SLL: case (funct7)
            7'b0000000: dinst.alufunc = SLL;
            default: dinst.itype = Unsupported;
          endcase
          fn_SR: case (funct7)
            7'b0000000: dinst.alufunc = SRL;
            7'b0100000: dinst.alufunc = SRA;
            default: dinst.itype = Unsupported;
          endcase
          default: dinst.itype = Unsupported;
        endcase
      end

      // branch operations (e.g. beq, bne, blt, bge, bltu, bgeu)
      op_BRANCH: begin
        dinst.imm = immB32;
        dinst.dst_valid = 1'b0;
        dinst.src1 = src1;
        dinst.src2 = src2;
        dinst.itype = BRANCH;

        case (funct3)
          fn_BEQ: dinst.brfunc = EQ;
          fn_BNE: dinst.brfunc = NEQ;
          fn_BLT: dinst.brfunc = LT;
          fn_BGE: dinst.brfunc = GE;
          fn_BLTU: dinst.brfunc = LTU;
          fn_BGEU: dinst.brfunc = GEU;
          default: dinst.itype = Unsupported;
        endcase
      end

      // jump and link
      op_JAL: begin
        dinst.itype = JAL;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;
        dinst.imm = immJ32;
        // TODO: do we need to make dSrc?
      end

      // load instruction
      op_LOAD: begin
        dinst.itype = LOAD;
        dinst.src1 = src1;
        dinst.imm = immI32;
        dinst.dst = dst;
        dinst.dst_valid = 1'b1;
        
        case (funct3)
          fn_LW: dinst.memfunc = LW;
          fn_LB: dinst.memfunc = LB;
          fn_LH: dinst.memfunc = LH;
          fn_LBU: dinst.memfunc = LBU;
          fn_LHU: dinst.memfunc = LHU;
          default: begin
            dinst.itype = Unsupported;
            dinst.dst_valid = 1'b0;
          end
        endcase
      end

      // store instruction
      op_STORE: begin
        dinst.itype = STORE;
        dinst.src1 = src1;
        dinst.src2 = src2;
        dinst.imm = immS32;
        
        case (funct3)
          fn_SW: dinst.memfunc = SW;
          fn_SB: dinst.memfunc = SB;
          fn_SH: dinst.memfunc = SH;
          default: dinst.itype = Unsupported;
        endcase
      end

      // jump and link register operation
      op_JALR: begin
        case (funct3)
          3'b000: begin
            dinst.itype = JALR;
            dinst.dst = dst;
            dinst.src1 = src1;
            dinst.imm = immI32;
          end
          default: dinst.itype = Unsupported;
        endcase
      end
    endcase
  end
endmodule

`default_nettype wire
