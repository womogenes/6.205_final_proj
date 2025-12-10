# DISCLAIMER: most of this file was LLM-generated

from proc_types import AluFunc, BrFunc, ExecInst, IType, MemFunc, DecodedInst
import random

TEST_CASES = []
EXEC_TEST_CASES = []

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
    
    for opcode, funct3, funct7, itype, alu_func in r_type_specs:
        for _ in range(N):  # Generate 3 random cases per instruction
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            
            encoded = encode_r_type(opcode, funct3, funct7, rd, rs1, rs2)
            decoded = DecodedInst(
                itype=itype, alu_func=alu_func, br_func=BrFunc.Null, mem_func=MemFunc.Null,
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
    
    for opcode, funct3, itype, alu_func in i_type_alu_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)  # 12-bit signed immediate
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alu_func=alu_func, br_func=BrFunc.Null, mem_func=MemFunc.Null,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
            )
            new_cases.append((encoded, decoded))
    
    # Shift I-type instructions (special encoding)
    shift_specs = [
        (0b0010011, 0b001, 0b0000000, IType.OPIMM, AluFunc.SLL),  # SLLI
        (0b0010011, 0b101, 0b0000000, IType.OPIMM, AluFunc.SRL),  # SRLI
        (0b0010011, 0b101, 0b0100000, IType.OPIMM, AluFunc.SRA),  # SRAI
    ]
    
    for opcode, funct3, funct7, itype, alu_func in shift_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            shamt = random.randint(0, 31)  # 5-bit shift amount
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, (funct7 << 5) | shamt)
            decoded = DecodedInst(
                itype=itype, alu_func=alu_func, br_func=BrFunc.Null, mem_func=MemFunc.Null,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=shamt + (funct7 << 5)
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
    
    for opcode, funct3, itype, mem_func in load_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            
            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alu_func=AluFunc.Null, br_func=BrFunc.Null, mem_func=mem_func,
                dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
            )
            new_cases.append((encoded, decoded))
    
    # Store instructions
    store_specs = [
        (0b0100011, 0b000, IType.STORE, MemFunc.SB),  # SB
        (0b0100011, 0b001, IType.STORE, MemFunc.SH),  # SH
        (0b0100011, 0b010, IType.STORE, MemFunc.SW),  # SW
    ]
    
    for opcode, funct3, itype, mem_func in store_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            
            encoded = encode_s_type(opcode, funct3, rs1, rs2, imm & 0xFFF)
            decoded = DecodedInst(
                itype=itype, alu_func=AluFunc.Null, br_func=BrFunc.Null, mem_func=mem_func,
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
    
    for opcode, funct3, itype, br_func in branch_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randrange(-4096, 4096, 2)  # 13-bit signed, even offset
            
            encoded = encode_b_type(opcode, funct3, rs1, rs2, imm & 0x1FFE)
            decoded = DecodedInst(
                itype=itype, alu_func=AluFunc.Null, br_func=br_func, mem_func=MemFunc.Null,
                dst=-1, dst_valid=0, src1=rs1, src2=rs2, imm=sign_extend_13(imm & 0x1FFE)
            )
            new_cases.append((encoded, decoded))
    
    # U-type instructions
    for _ in range(N):  # LUI
        rd = random.randint(1, 31)
        imm = random.randint(0, 0xFFFFF)  # 20-bit immediate
        
        encoded = encode_u_type(0b0110111, rd, imm)
        decoded = DecodedInst(
            itype=IType.LUI, alu_func=AluFunc.Null, br_func=BrFunc.Null, mem_func=MemFunc.Null,
            dst=rd, dst_valid=1, src1=-1, src2=-1, imm=imm << 12
        )
        new_cases.append((encoded, decoded))
    
    # JAL instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        imm = random.randrange(-1048576, 1048576, 2)  # 21-bit signed, even offset
        
        encoded = encode_j_type(0b1101111, rd, imm & 0x1FFFFE)
        decoded = DecodedInst(
            itype=IType.JAL, alu_func=AluFunc.Null, br_func=BrFunc.Null, mem_func=MemFunc.Null,
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
            itype=IType.JALR, alu_func=AluFunc.Null, br_func=BrFunc.Null, mem_func=MemFunc.Null,
            dst=rd, dst_valid=1, src1=rs1, src2=-1, imm=sign_extend_12(imm & 0xFFF)
        )
        new_cases.append((encoded, decoded))
    
    return new_cases

# Generate and add random test cases
RANDOM_TEST_CASES = generate_random_test_cases(N=1000)
TEST_CASES.extend(RANDOM_TEST_CASES)

def to_signed_32(val):
    """Convert to signed 32-bit integer"""
    val = val & 0xFFFFFFFF
    if val & 0x80000000:
        return val - 0x100000000
    return val

def generate_exec_test_cases(N):
    """Generate test cases for execute stage: (inst, r_val1, r_val2, pc, expected_ExecInst)"""
    exec_cases = []

    # R-type instructions (OP)
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

    for opcode, funct3, funct7, itype, alu_func in r_type_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_r_type(opcode, funct3, funct7, rd, rs1, rs2)

            # Compute expected ALU output
            if alu_func == AluFunc.ADD:
                data = (r_val1 + r_val2) & 0xFFFFFFFF
            elif alu_func == AluFunc.SUB:
                data = (r_val1 - r_val2) & 0xFFFFFFFF
            elif alu_func == AluFunc.SLL:
                data = (r_val1 << (r_val2 & 0x1F)) & 0xFFFFFFFF
            elif alu_func == AluFunc.SLT:
                data = 1 if to_signed_32(r_val1) < to_signed_32(r_val2) else 0
            elif alu_func == AluFunc.SLTU:
                data = 1 if r_val1 < r_val2 else 0
            elif alu_func == AluFunc.XOR:
                data = r_val1 ^ r_val2
            elif alu_func == AluFunc.SRL:
                data = r_val1 >> (r_val2 & 0x1F)
            elif alu_func == AluFunc.SRA:
                data = to_signed_32(r_val1) >> (r_val2 & 0x1F)
                data = data & 0xFFFFFFFF
            elif alu_func == AluFunc.OR:
                data = r_val1 | r_val2
            elif alu_func == AluFunc.AND:
                data = r_val1 & r_val2

            expected = ExecInst(
                itype=itype,
                mem_func=MemFunc.Null,
                dst=rd,
                dst_valid=1,
                data=data,
                addr=r_val1,  # r_val1 + 0 for OP instructions
                next_pc=(pc + 4) & 0xFFFFFFFF
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # I-type ALU instructions (OPIMM)
    i_type_alu_specs = [
        (0b0010011, 0b000, IType.OPIMM, AluFunc.ADD),   # ADDI
        (0b0010011, 0b010, IType.OPIMM, AluFunc.SLT),   # SLTI
        (0b0010011, 0b011, IType.OPIMM, AluFunc.SLTU),  # SLTIU
        (0b0010011, 0b100, IType.OPIMM, AluFunc.XOR),   # XORI
        (0b0010011, 0b110, IType.OPIMM, AluFunc.OR),    # ORI
        (0b0010011, 0b111, IType.OPIMM, AluFunc.AND),   # ANDI
    ]

    for opcode, funct3, itype, alu_func in i_type_alu_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            imm_signed = sign_extend_12(imm & 0xFFF)

            # Compute expected ALU output
            if alu_func == AluFunc.ADD:
                data = (r_val1 + imm_signed) & 0xFFFFFFFF
            elif alu_func == AluFunc.SLT:
                data = 1 if to_signed_32(r_val1) < to_signed_32(imm_signed) else 0
            elif alu_func == AluFunc.SLTU:
                data = 1 if r_val1 < (imm_signed & 0xFFFFFFFF) else 0
            elif alu_func == AluFunc.XOR:
                data = r_val1 ^ (imm_signed & 0xFFFFFFFF)
            elif alu_func == AluFunc.OR:
                data = r_val1 | (imm_signed & 0xFFFFFFFF)
            elif alu_func == AluFunc.AND:
                data = r_val1 & (imm_signed & 0xFFFFFFFF)

            expected = ExecInst(
                itype=itype,
                mem_func=MemFunc.Null,
                dst=rd,
                dst_valid=1,
                data=data,
                addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
                next_pc=(pc + 4) & 0xFFFFFFFF
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # Shift I-type instructions
    shift_specs = [
        (0b0010011, 0b001, 0b0000000, IType.OPIMM, AluFunc.SLL),  # SLLI
        (0b0010011, 0b101, 0b0000000, IType.OPIMM, AluFunc.SRL),  # SRLI
        (0b0010011, 0b101, 0b0100000, IType.OPIMM, AluFunc.SRA),  # SRAI
    ]

    for opcode, funct3, funct7, itype, alu_func in shift_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            shamt = random.randint(0, 31)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_i_type(opcode, funct3, rd, rs1, (funct7 << 5) | shamt)
            imm = shamt + (funct7 << 5)

            if alu_func == AluFunc.SLL:
                data = (r_val1 << shamt) & 0xFFFFFFFF
            elif alu_func == AluFunc.SRL:
                data = r_val1 >> shamt
            elif alu_func == AluFunc.SRA:
                data = to_signed_32(r_val1) >> shamt
                data = data & 0xFFFFFFFF

            expected = ExecInst(
                itype=itype,
                mem_func=MemFunc.Null,
                dst=rd,
                dst_valid=1,
                data=data,
                addr=(r_val1 + imm) & 0xFFFFFFFF,
                next_pc=(pc + 4) & 0xFFFFFFFF
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # Load instructions
    load_specs = [
        (0b0000011, 0b000, IType.LOAD, MemFunc.LB),   # LB
        (0b0000011, 0b001, IType.LOAD, MemFunc.LH),   # LH
        (0b0000011, 0b010, IType.LOAD, MemFunc.LW),   # LW
        (0b0000011, 0b100, IType.LOAD, MemFunc.LBU),  # LBU
        (0b0000011, 0b101, IType.LOAD, MemFunc.LHU),  # LHU
    ]

    for opcode, funct3, itype, mem_func in load_specs:
        for _ in range(N):
            rd = random.randint(1, 31)
            rs1 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_i_type(opcode, funct3, rd, rs1, imm & 0xFFF)
            imm_signed = sign_extend_12(imm & 0xFFF)

            expected = ExecInst(
                itype=itype,
                mem_func=mem_func,
                dst=rd,
                dst_valid=1,
                data=0,  # Data will be filled by memory stage
                addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
                next_pc=(pc + 4) & 0xFFFFFFFF
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # Store instructions
    store_specs = [
        (0b0100011, 0b000, IType.STORE, MemFunc.SB),  # SB
        (0b0100011, 0b001, IType.STORE, MemFunc.SH),  # SH
        (0b0100011, 0b010, IType.STORE, MemFunc.SW),  # SW
    ]

    for opcode, funct3, itype, mem_func in store_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randint(-2048, 2047)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_s_type(opcode, funct3, rs1, rs2, imm & 0xFFF)
            imm_signed = sign_extend_12(imm & 0xFFF)

            expected = ExecInst(
                itype=itype,
                mem_func=mem_func,
                dst=0,
                dst_valid=0,
                data=r_val2,
                addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
                next_pc=(pc + 4) & 0xFFFFFFFF
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # Branch instructions
    branch_specs = [
        (0b1100011, 0b000, IType.BRANCH, BrFunc.EQ),   # BEQ
        (0b1100011, 0b001, IType.BRANCH, BrFunc.NEQ),  # BNE
        (0b1100011, 0b100, IType.BRANCH, BrFunc.LT),   # BLT
        (0b1100011, 0b101, IType.BRANCH, BrFunc.GE),   # BGE
        (0b1100011, 0b110, IType.BRANCH, BrFunc.LTU),  # BLTU
        (0b1100011, 0b111, IType.BRANCH, BrFunc.GEU),  # BGEU
    ]

    for opcode, funct3, itype, br_func in branch_specs:
        for _ in range(N):
            rs1 = random.randint(0, 31)
            rs2 = random.randint(0, 31)
            imm = random.randrange(-4096, 4096, 2)
            r_val1 = random.randint(0, 0xFFFFFFFF)
            r_val2 = random.randint(0, 0xFFFFFFFF)
            pc = random.randrange(0, 0x10000, 4)

            encoded = encode_b_type(opcode, funct3, rs1, rs2, imm & 0x1FFE)
            imm_signed = sign_extend_13(imm & 0x1FFE)

            # Compute branch condition
            if br_func == BrFunc.EQ:
                taken = (r_val1 == r_val2)
            elif br_func == BrFunc.NEQ:
                taken = (r_val1 != r_val2)
            elif br_func == BrFunc.LT:
                taken = to_signed_32(r_val1) < to_signed_32(r_val2)
            elif br_func == BrFunc.GE:
                taken = to_signed_32(r_val1) >= to_signed_32(r_val2)
            elif br_func == BrFunc.LTU:
                taken = r_val1 < r_val2
            elif br_func == BrFunc.GEU:
                taken = r_val1 >= r_val2

            next_pc = (pc + imm_signed) & 0xFFFFFFFF if taken else (pc + 4) & 0xFFFFFFFF

            expected = ExecInst(
                itype=itype,
                mem_func=MemFunc.Null,
                dst=0,
                dst_valid=0,
                data=0,
                addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
                next_pc=next_pc
            )
            exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # LUI instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        imm = random.randint(0, 0xFFFFF)
        r_val1 = random.randint(0, 0xFFFFFFFF)
        r_val2 = random.randint(0, 0xFFFFFFFF)
        pc = random.randrange(0, 0x10000, 4)

        encoded = encode_u_type(0b0110111, rd, imm)

        expected = ExecInst(
            itype=IType.LUI,
            mem_func=MemFunc.Null,
            dst=rd,
            dst_valid=1,
            data=(imm << 12) & 0xFFFFFFFF,
            addr=(r_val1 + ((imm << 12) & 0xFFFFFFFF)) & 0xFFFFFFFF,
            next_pc=(pc + 4) & 0xFFFFFFFF
        )
        exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # AUIPC instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        imm = random.randint(0, 0xFFFFF)
        r_val1 = random.randint(0, 0xFFFFFFFF)
        r_val2 = random.randint(0, 0xFFFFFFFF)
        pc = random.randrange(0, 0x10000, 4)

        encoded = encode_u_type(0b0010111, rd, imm)

        expected = ExecInst(
            itype=IType.AUIPC,
            mem_func=MemFunc.Null,
            dst=rd,
            dst_valid=1,
            data=(pc + (imm << 12)) & 0xFFFFFFFF,
            addr=(r_val1 + ((imm << 12) & 0xFFFFFFFF)) & 0xFFFFFFFF,
            next_pc=(pc + 4) & 0xFFFFFFFF
        )
        exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # JAL instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        imm = random.randrange(-1048576, 1048576, 2)
        r_val1 = random.randint(0, 0xFFFFFFFF)
        r_val2 = random.randint(0, 0xFFFFFFFF)
        pc = random.randrange(0, 0x10000, 4)

        encoded = encode_j_type(0b1101111, rd, imm & 0x1FFFFE)
        imm_signed = sign_extend_21(imm & 0x1FFFFE)

        expected = ExecInst(
            itype=IType.JAL,
            mem_func=MemFunc.Null,
            dst=rd,
            dst_valid=1,
            data=(pc + 4) & 0xFFFFFFFF,
            addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
            next_pc=(pc + imm_signed) & 0xFFFFFFFF
        )
        exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    # JALR instructions
    for _ in range(N):
        rd = random.randint(1, 31)
        rs1 = random.randint(0, 31)
        imm = random.randint(-2048, 2047)
        r_val1 = random.randint(0, 0xFFFFFFFF)
        r_val2 = random.randint(0, 0xFFFFFFFF)
        pc = random.randrange(0, 0x10000, 4)

        encoded = encode_i_type(0b1100111, 0b000, rd, rs1, imm & 0xFFF)
        imm_signed = sign_extend_12(imm & 0xFFF)

        expected = ExecInst(
            itype=IType.JALR,
            mem_func=MemFunc.Null,
            dst=rd,
            dst_valid=1,
            data=(pc + 4) & 0xFFFFFFFF,
            addr=(r_val1 + imm_signed) & 0xFFFFFFFF,
            next_pc=((r_val1 + imm_signed) & ~1) & 0xFFFFFFFF
        )
        exec_cases.append((encoded, r_val1, r_val2, pc, expected))

    return exec_cases

# Generate execute test cases
EXEC_TEST_CASES = generate_exec_test_cases(N=100)
