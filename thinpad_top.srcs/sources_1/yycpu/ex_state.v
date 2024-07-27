`include "defines.v"

module ex_state(
    input wire                              clk,
    input wire                              rst,
    
    // ִ�н׶ε�������Ϣ
    input wire [4:0]                        aluop_i,
    input wire [2:0]                        alusel_i,
    input wire [31:0]                       reg1_i,
    input wire [31:0]                       reg2_i,
    input wire [4:0]                        wd_i,
    input wire                              wreg_i,

    // �ӳٲ����?
    input wire [31:0]                       link_address_i,

    // ����/�洢ָ��
    input wire [31:0]                       inst_i,
    output reg [4:0]                        wd_o,
    output reg                              wreg_o,
    output reg [31:0]                       wdata_o,

    // �ô�������
    output wire [4:0]                       aluop_o,
    output wire [31:0]                      mem_addr_o,
    output wire [31:0]                      reg2_o,
    
    output reg                              stall_from_ex 
);
    // �ڲ��źŶ���
    reg [31:0]  logicout, shiftres, arithmeticres, mulres_32;
    wire [31:0] result_sum, result_mul;
    wire [31:0] opdata1_mult, opdata2_mult;
    wire [31:0] reg2_i_sign;
    //wire overflow_flag;

    // �ô���������ֵ
    assign aluop_o = aluop_i;
    assign reg2_o = reg2_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
    assign reg2_i_sign = (aluop_i == `SUBU_OP) ? (~reg2_i) + 1 : reg2_i;
    assign result_sum = reg1_i + reg2_i_sign;
    // assign overflow_flag = ((!reg1_i[31] && !reg2_i_sign[31]) && result_sum[31]) || //正数加�?�数得负�?
    //                         ((reg1_i[31] && reg2_i_sign[31]) && (!result_sum[31])); //负数加负数得正数

    // �߼�����
    always @(*) begin
        logicout = (rst == `RstEnable) ? `ZeroWord :
			(aluop_i ==  `OR_OP) ? (reg1_i | reg2_i) :
			(aluop_i ==  `AND_OP) ? (reg1_i & reg2_i) :
			(aluop_i ==  `XOR_OP) ? (reg1_i ^ reg2_i) : `ZeroWord;
    end

    // ��λ����
    always @(*) begin
        shiftres = (rst == `RstEnable) ? `ZeroWord :
			(aluop_i ==  `SLL_OP) ? (reg2_i << reg1_i[4:0]) :
			(aluop_i ==  `SRL_OP) ? (reg2_i >> reg1_i[4:0]) :
			(aluop_i ==  `SRA_OP) ? (({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0]) : `ZeroWord;
    end

    // ��������
    always @(*) begin
        arithmeticres = (rst == `RstEnable) ? `ZeroWord :
			(aluop_i ==  `ADDU_OP || aluop_i == `SUBU_OP) ? result_sum :
			(aluop_i ==  `SLT_OP) ? (($signed(reg1_i) < $signed(reg2_i)) ? 32'b1 : 32'b0) : `ZeroWord;
	end

    assign opdata1_mult = (aluop_i == `MUL_OP) ? reg1_i : 32'b0;
    assign opdata2_mult = (aluop_i == `MUL_OP) ? reg2_i : 32'b0;

    mult_gen_1 mult_gen_1(
        .A(opdata1_mult),
        .B(opdata2_mult),
        .P(result_mul)
    );

    always @(*) begin
        mulres_32 = (rst == `RstEnable) ? 32'd0 :
            (aluop_i == `MUL_OP) ? result_mul : 32'd0;
    end

    always @(*) begin
        wd_o = wd_i;
        wreg_o = wreg_i;
        stall_from_ex = `NoStop;
        case (alusel_i)
             `RES_LOGIC: 		wdata_o = logicout;
             `RES_SHIFT: 		wdata_o = shiftres;
             `RES_ARITHMETIC: 	wdata_o = arithmeticres;
             `RES_MUL: 			wdata_o = mulres_32;
             `RES_JUMP_BRANCH: 	wdata_o = link_address_i;
            default: 			wdata_o = `ZeroWord;
        endcase
    end

endmodule