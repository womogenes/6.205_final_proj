from proc_types import AluFunc, BrFunc, IType, MemFunc, DecodedInst
import random

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

# RISC-V Instruction Encoders
def encode_r_type(opcode, funct3, funct7, rd, rs1, rs2):
    """Encode R-type instruction"""
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i_type(opcode, funct3, rd, rs1, imm):
    """Encode I-type instruction"""
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s_type(opcode, funct3, rs1, rs2, imm):
    """Encode S-type instruction"""
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b_type(opcode, funct3, rs1, rs2, imm):
    """Encode B-type instruction"""
    imm_12 = (imm >> 12) & 0x1
    imm_11 = (imm >> 11) & 0x1
    imm_10_5 = (imm >> 5) & 0x3F
    imm_4_1 = (imm >> 1) & 0xF
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

def encode_u_type(opcode, rd, imm):
    """Encode U-type instruction"""
    return (imm << 12) | (rd << 7) | opcode

def encode_j_type(opcode, rd, imm):
    """Encode J-type instruction"""
    imm_20 = (imm >> 20) & 0x1
    imm_19_12 = (imm >> 12) & 0xFF
    imm_11 = (imm >> 11) & 0x1
    imm_10_1 = (imm >> 1) & 0x3FF
    return (imm_20 << 31) | (imm_19_12 << 12) | (imm_11 << 20) | (imm_10_1 << 21) | (rd << 7) | opcode

def sign_extend_12(imm):
    """Sign extend 12-bit immediate to 32-bit"""
    if imm & 0x800:  # Check if bit 11 is set
        return imm | 0xFFFFF000
    return imm

def sign_extend_13(imm):
    """Sign extend 13-bit immediate to 32-bit (for branches)"""
    if imm & 0x1000:  # Check if bit 12 is set
        return imm | 0xFFFFE000
    return imm

def sign_extend_21(imm):
    """Sign extend 21-bit immediate to 32-bit (for JAL)"""
    if imm & 0x100000:  # Check if bit 20 is set
        return imm | 0xFFE00000
    return imm

def generate_random_test_cases(N):
    """Generate random test cases for each instruction type"""
    # random.seed(42)
    new_cases = []
    
    # R-type instructions
    r_type_specs = [
        (0b0110011, 0b000, 0b0000000, IType.OP, AluFunc.ADD),   # ADD
        (0b0110011, 0b000, 0b0100000, IType.OP, AluFunc.SUB),   # SUB
        (0b0110011, 0b001, 0b0000000, IType.OP, AluFunc.SLL),   # SLL
        (0b0110011, 0b010, 0b0000000, IType.OP, AluFunc.SLT),   # SLT
        (0b0110011, 0b011, 0b0000000, IType.OP, AluFunc.SLTU),  # SLTU
        (0b0110011, 0b100, 0b0000000, IType.OP, AluFunc.XOR),   # XOR
        (0b0110011, 0b101, 0b0000000, IType.OP, AluFunc.SRL),   # SRL
        (0b0110011, 0b101, 0b0100000, IType.OP, AluFunc.SRA),   # SRA
        (0b0110011, 0b110, 0b0000000, IType.OP, AluFunc.OR),    # OR
        (0b0110011, 0b111, 0b0000000, IType.OP, AluFunc.AND),   # AND
    ]
    
    for opcode, funct3, funct7, itype, alufunc in r_type_specs:
        for _ in range(N):  # Generate 3 random cases per instruction
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            
            encoded = encode_r_type(opcode, funct3, funct7, rd, rs1, rs2)
            decoded = DecodedInst(
                itype=itype, alufunc=alufunc, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
                dst=rd, dst_valid=1, src1=rs1, src2=rs2, imm=0
            )
            new_cases.append((encoded, decoded))
    
    # I-type ALU instructions
    i_type_alu_specs = [
        (0b0010011, 0b000, IType.OPIMM, AluFunc.ADD),   # ADDI
        (0b0010011, 0b010, IType.OPIMM, AluFunc.SLT),   # SLTI
        (0b0010011, 0b011, IType.OPIMM, AluFunc.SLTU),  # SLTIU
        (0b0010011, 0b100, IType.OPIMM, AluFunc.XOR),   # XORI
        (0b0010011, 0b110, IType.OPIMM, AluFunc.OR),    # ORI
        (0b0010011, 0b111, IType.OPIMM, AluFunc.AND),   # ANDI
    ]
    
    for opcode, funct3, itype, alufunc in i_type_alu_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)  # 12-bit signed immediate
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alufunc=alufunc, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
            )
            new_cases.append((encoded, decoded))
    
    # Shift I-type instructions (special encoding)
    shift_specs = [
        (0b0010011, 0b001, 0b0000000, IType.OPIMM, AluFunc.SLL),  # SLLI
        (0b0010011, 0b101, 0b0000000, IType.OPIMM, AluFunc.SRL),  # SRLI
        (0b0010011, 0b101, 0b0100000, IType.OPIMM, AluFunc.SRA),  # SRAI
    ]
    
    for opcode, funct3, funct7, itype, alufunc in shift_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            shamt = random.randint(0, 31)  # 5-bit shift amount
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, (funct7 << 5) | shamt)
            decoded = DecodedInst(
                itype=itype, alufunc=alufunc, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=shamt
            )
            new_cases.append((encoded, decoded))
    
    # Load instructions
    load_specs = [
        (0b0000011, 0b000, IType.LOAD, MemFunc.LB),   # LB
        (0b0000011, 0b001, IType.LOAD, MemFunc.LH),   # LH
        (0b0000011, 0b010, IType.LOAD, MemFunc.LW),   # LW
        (0b0000011, 0b100, IType.LOAD, MemFunc.LBU),  # LBU
        (0b0000011, 0b101, IType.LOAD, MemFunc.LHU),  # LHU
    ]
    
    for opcode, funct3, itype, memfunc in load_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=memfunc,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
            )
            new_cases.append((encoded, decoded))
    
    # Store instructions
    store_specs = [
        (0b0100011, 0b000, IType.STORE, MemFunc.SB),  # SB
        (0b0100011, 0b001, IType.STORE, MemFunc.SH),  # SH
        (0b0100011, 0b010, IType.STORE, MemFunc.SW),  # SW
    ]
    
    for opcode, funct3, itype, memfunc in store_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            
            encoded = encode_s_type(opcode, funct3, rs1, rs2, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=memfunc,
                dst=-1, dst_valid=0, src1=rs1, src2=rs2, imm=sign_extend_12(imm & 0xFFF)
            )
            new_cases.append((encoded, decoded))
    
    # Branch instructions
    branch_specs = [
        (0b1100011, 0b000, IType.BRANCH, BrFunc.EQ),   # BEQ
        (0b1100011, 0b001, IType.BRANCH, BrFunc.NEQ),  # BNE
        (0b1100011, 0b100, IType.BRANCH, BrFunc.LT),   # BLT
        (0b1100011, 0b101, IType.BRANCH, BrFunc.GE),   # BGE
        (0b1100011, 0b110, IType.BRANCH, BrFunc.LTU),  # BLTU
        (0b1100011, 0b111, IType.BRANCH, BrFunc.GEU),  # BGEU
    ]
    
    for opcode, funct3, itype, brfunc in branch_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randrange(-4096, 4096, 2)  # 13-bit signed, even offset
            
            encoded = encode_b_type(opcode, funct3, rs1, rs2, imm & 0x1FFE)
            decoded = DecodedInst(
                itype=itype, alufunc=AluFunc.Null, brfunc=brfunc, memfunc=MemFunc.Null,
                dst=-1, dst_valid=0, src1=rs1, src2=rs2, imm=sign_extend_13(imm & 0x1FFE)
            )
            new_cases.append((encoded, decoded))
    
    # U-type instructions
    for _ in range(N):  # LUI
        rd = random.randint(1, 31)
        imm = random.randint(0, 0xFFFFF)  # 20-bit immediate
        
        encoded = encode_u_type(0b0110111, rd, imm)
        decoded = DecodedInst(
            itype=IType.LUI, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=rd, dst_valid=1, src1=-1, src2=-1, imm=imm << 12
        )
        new_cases.append((encoded, decoded))
    
    # JAL instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        imm = random.randrange(-1048576, 1048576, 2)  # 21-bit signed, even offset
        
        encoded = encode_j_type(0b1101111, rd, imm & 0x1FFFFE)
        decoded = DecodedInst(
            itype=IType.JAL, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=rd, dst_valid=1, src1=-1, src2=-1, imm=sign_extend_21(imm & 0x1FFFFE)
        )
        new_cases.append((encoded, decoded))
    
    # JALR instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        rs1 = random.randint(0, 31)
        imm = random.randint(-2048, 2047)
        
        encoded = encode_i_type(0b1100111, 0b000, rd, rs1, imm & 0xFFF)
        decoded = DecodedInst(
            itype=IType.JALR, alufunc=AluFunc.Null, brfunc=BrFunc.Null, memfunc=MemFunc.Null,
            dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
        )
        new_cases.append((encoded, decoded))
    
    return new_cases

# Generate and add random test cases
RANDOM_TEST_CASES = generate_random_test_cases(N=1000)
TEST_CASES.extend(RANDOM_TEST_CASES)
