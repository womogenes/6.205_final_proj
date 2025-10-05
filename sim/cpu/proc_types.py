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
            self.alufunc = AluFunc(intt(dinst[4:8]))
            self.brfunc = BrFunc(intt(dinst[8:11]))
            self.memfunc = MemFunc(intt(dinst[11:14]))
            self.dst = intt(dinst[14:19])
            self.dst_valid = intt(dinst[19])
            self.src1 = intt(dinst[20:25])
            self.src2 = intt(dinst[25:30])
            self.imm = intt(dinst[30:62])
        else:
            # Extract from kwargs
            self.itype = kwargs.get("itype")
            self.alufunc = kwargs.get("alufunc")
            self.brfunc = kwargs.get("brfunc")
            self.memfunc = kwargs.get("memfunc")
            self.dst = kwargs.get("dst")
            self.dst_valid = kwargs.get("dst_valid")
            self.src1 = kwargs.get("src1")
            self.src2 = kwargs.get("src2")
            self.imm = kwargs.get("imm")
    
    def __str__(self):
        return f"DecodedInst(itype={self.itype}, alufunc={self.alufunc}, brfunc={self.brfunc}, memfunc={self.memfunc}, dst={self.dst}, dst_valid={self.dst_valid}, src1={self.src1}, src2={self.src2}, imm={self.imm})" 
