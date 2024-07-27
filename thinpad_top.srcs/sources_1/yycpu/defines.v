
//宏定义
`define RstEnable 1'b1
`define RstDisable 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define ZeroWord 32'h00000000

//逻辑
`define  ORI  6'b001101
`define  LUI  6'b001111
`define  AND  6'b100100
`define  ANDI 6'b001100
`define  OR   6'b100101
`define  XOR  6'b100110
`define  XORI 6'b001110

//移位
`define  SLL  6'b000000
`define  SRL  6'b000010
`define  SRA  6'b000011

//运算
`define  ADD  6'b100000
`define  ADDI  6'b001000
`define  ADDU  6'b100001
`define  ADDIU  6'b001001
`define  SLT  6'b101010
// `define  SLTI  6'b001010
// `define  SLTU  6'b101011
// `define  SLTIU  6'b001011
`define  SUB  6'b100010
`define  SUBU  6'b100011
`define  MUL 6'b011100

//分支跳转
`define  BNE  6'b000101
`define  BEQ  6'b000100
`define  BGTZ  6'b000111
`define  BGEZ  5'b00001
`define  J  6'b000010
`define  JAL  6'b000011
`define  JR  6'b001000
`define  JALR 6'b001001

//访存
`define  LW  6'b100011
`define  SW  6'b101011
`define  LB  6'b100000
`define  SB  6'b101000

`define  NOP 6'b000000
`define  R_INST 6'b000000

//AluOp
//逻辑
`define  OR_OP   5'd1
`define  ORI_OP  5'd2
`define  LUI_OP  5'd3
`define  AND_OP  5'd4
`define  XOR_OP  5'd5
`define  XORI_OP 5'd6
`define  ANDI_OP 5'd7

//移位
`define  SLL_OP  5'd8
`define  SRL_OP  5'd10
`define  SRA_OP  5'd11

//运算
`define  ADDU_OP 5'd12
`define  SUBU_OP  5'd13
`define  MUL_OP  5'd15
`define  SLT_OP  5'd16

//分支跳转
`define  BNE_OP  5'd17
`define  BLEZ_OP 5'd18
`define  BEQ_OP  5'd19
`define  J_OP    5'd20
`define  JAL_OP  5'd21
`define  JR_OP   5'd22
`define  JALR_OP 5'd23
`define  BGTZ_OP 5'd24
`define  BGEZ_OP 5'd25

//访存
`define  LW_OP   5'd26
`define  SW_OP   5'd27
`define  LB_OP   5'd28
`define  SB_OP   5'd29

`define  NOP_OP  5'd30

//AluSel
`define  RES_LOGIC 3'b001
`define  RES_SHIFT 3'b010
`define  RES_ARITHMETIC 3'b100	
`define  RES_MUL  3'b101
`define  RES_JUMP_BRANCH 3'b110
`define  RES_LOAD_STORE  3'b111
`define  RES_NOP  3'b000