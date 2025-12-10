from enum import Enum
from utils import intt

class AluFunc(Enum):
    Null = -1
    ADD = 0
    SUB = 1
    AND = 2
    OR = 3
    XOR = 4
    SLT = 5
    SLTU = 6
    SLL = 7
    SRL = 8
    SRA = 9

class BrFunc(Enum):
    Null = -1
    EQ = 0
    NEQ = 1
    LT = 2
    LTU = 3
    GE = 4
    GEU = 5

class MemFunc(Enum):
    Null = -1
    LW = 0
    LH = 1
    LHU = 2
    LB = 3
    LBU = 4
    SW = 5
    SH = 6
    SB = 7

class IType(Enum):
    Null = -1
    OP = 0
    OPIMM = 1
    BRANCH = 2
    LUI = 3
    JAL = 4
    JALR = 5
    LOAD = 6
    STORE = 7
    AUIPC = 8
    MUL = 9
    Unsupported = 10

class DecodedInst():
    def __init__(self, dinst: str = None, **kwargs):
        if dinst:
            # Extract from bitstring
            self.itype = IType(intt(dinst[0:4]))
            self.alu_func = AluFunc(intt(dinst[4:8]))
            self.br_func = BrFunc(intt(dinst[8:11]))
            self.mem_func = MemFunc(intt(dinst[11:14]))
            self.dst = intt(dinst[14:19])
            self.dst_valid = intt(dinst[19])
            self.src1 = intt(dinst[20:25])
            self.src2 = intt(dinst[25:30])
            self.imm = intt(dinst[30:62])
        else:
            # Extract from kwargs
            self.itype = kwargs.get("itype")
            self.alu_func = kwargs.get("alu_func")
            self.br_func = kwargs.get("br_func")
            self.mem_func = kwargs.get("mem_func")
            self.dst = kwargs.get("dst")
            self.dst_valid = kwargs.get("dst_valid")
            self.src1 = kwargs.get("src1")
            self.src2 = kwargs.get("src2")
            self.imm = kwargs.get("imm")
    
    def __str__(self):
        return f"DecodedInst(itype={self.itype}, alu_func={self.alu_func}, br_func={self.br_func}, mem_func={self.mem_func}, dst={self.dst}, dst_valid={self.dst_valid}, src1={self.src1}, src2={self.src2}, imm={self.imm})" 


class ExecInst():
    def __init__(self, einst: str = None, **kwargs):
        if einst:
            # Extract from bitstring
            self.itype = IType(intt(einst[0:4]))
            self.mem_func = MemFunc(intt(einst[4:7]))
            self.dst = intt(einst[7:12])
            self.dst_valid = intt(einst[12])
            self.data = intt(einst[13:45])
            self.addr = intt(einst[45:77])
            self.next_pc = intt(einst[77:109])
        else:
            # Extract from kwargs
            self.itype = kwargs.get("itype")
            self.mem_func = kwargs.get("mem_func")
            self.dst = kwargs.get("dst")
            self.dst_valid = kwargs.get("dst_valid")
            self.data = kwargs.get("data")
            self.addr = kwargs.get("addr")
            self.next_pc = kwargs.get("next_pc")

    def __str__(self):
        return f"ExecInst(itype={self.itype}, mem_func={self.mem_func}, dst={self.dst}, dst_valid={self.dst_valid}, data={self.data}, addr={self.addr}, next_pc={self.next_pc})"
