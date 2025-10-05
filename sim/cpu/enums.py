from enum import Enum

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
