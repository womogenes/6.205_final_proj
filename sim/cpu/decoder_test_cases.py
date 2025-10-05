from proc_types import AluFunc, BrFunc, IType, MemFunc, DecodedInst

TEST_CASES = [
    (   # LUI
        0b0000_0000_0000_0000_0000_0001_00001_0110111,
        DecodedInst(
            itype=IType.LUI, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=1, dst_valid=1, src1=-1, src2=-1, imm=1 << 12,
        )
    ),
    (   # JAL
        0b0000_0000_0100_0000_0000_00010_1101111,
        DecodedInst(
            itype=IType.JAL, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=-1, src2=-1, imm=4,
        )
    ),
    (   # JALR
        0b0000_0000_0100_00010_000_00010_1100111,
        DecodedInst(
            itype=IType.JALR, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=2, src2=-1, imm=4,
        )
    ),
    (   # BEQ
        0b0000_0000_0010_0001_0000_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.EQ, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # BNE
        0b0000_0000_0010_0001_0001_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.NEQ, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # BLT
        0b0000_0000_0010_0001_0100_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.LT, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # BGE
        0b0000_0000_0010_0001_0101_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.GE, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # BLTU
        0b0000_0000_0010_0001_0110_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.LTU, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # BGEU
        0b0000_0000_0010_0001_0111_0100_01100011,
        DecodedInst(
            itype=IType.BRANCH, alufunc=AluFunc.Null, brfunc=BrFunc.GEU, memfunc=MemFunc.Null,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # LB
        0b0000_0000_0100_00001_000_00010_0000011,
        DecodedInst(
            itype=IType.LOAD, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.LB,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # LH
        0b0000_0000_0100_00001_001_00010_0000011,
        DecodedInst(
            itype=IType.LOAD, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.LH,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # LW
        0b0000_0000_0100_00001_010_00010_0000011,
        DecodedInst(
            itype=IType.LOAD, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.LW,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # LBU
        0b0000_0000_0100_00001_100_00010_0000011,
        DecodedInst(
            itype=IType.LOAD, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.LBU,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # LHU
        0b0000_0000_0100_00001_101_00010_0000011,
        DecodedInst(
            itype=IType.LOAD, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.LHU,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SB
        0b0000_0000_0010_00001_000_00100_0100011,
        DecodedInst(
            itype=IType.STORE, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.SB,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # SH
        0b0000_0000_0010_00001_001_00100_0100011,
        DecodedInst(
            itype=IType.STORE, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.SH,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # SW
        0b0000_0000_0010_00001_010_00100_0100011,
        DecodedInst(
            itype=IType.STORE, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.SW,
            dst=-1, dst_valid=0, src1=1, src2=2, imm=4,
        )
    ),
    (   # ADDI
        0b0000_0000_0100_00001_000_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.ADD, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SLTI
        0b0000_0000_0100_00001_010_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.SLT, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SLTIU
        0b0000_0000_0100_00001_011_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.SLTU, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # XORI
        0b0000_0000_0100_00001_100_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.XOR, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # ORI
        0b0000_0000_0100_00001_110_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.OR, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # ANDI
        0b0000_0000_0100_00001_111_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.AND, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SLLI
        0b0000_0000_0100_00001_001_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.SLL, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SRLI
        0b0000_0000_0100_00001_101_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.SRL, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # SRAI
        0b0100_0000_0100_00001_101_00010_0010011,
        DecodedInst(
            itype=IType.OPIMM, alufunc=AluFunc.SRA, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=2, dst_valid=1, src1=1, src2=-1, imm=4,
        )
    ),
    (   # ADD
        0b0000_0000_0010_00001_000_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.ADD, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SUB
        0b0100_0000_0010_00001_000_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SUB, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SLL
        0b0000_0000_0010_00001_001_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SLL, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SLT
        0b0000_0000_0010_00001_010_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SLT, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SLTU
        0b0000_0000_0010_00001_011_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SLTU, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # XOR
        0b0000_0000_0010_00001_100_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.XOR, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SRL
        0b0000_0000_0010_00001_101_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SRL, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # SRA
        0b0100_0000_0010_00001_101_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.SRA, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # OR
        0b0000_0000_0010_00001_110_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.OR, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
    (   # AND
        0b0000_0000_0010_00001_111_00011_0110011,
        DecodedInst(
            itype=IType.OP, alufunc=AluFunc.AND, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=3, dst_valid=1, src1=1, src2=2, imm=0,
        )
    ),
]
