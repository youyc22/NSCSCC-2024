`include "defines.v"

module ex_state(
    input wire clk,
    input wire rst,
    
    // ִ�н׶ε�������Ϣ
    input wire [4:0] aluop_i,
    input wire [2:0] alusel_i,
    input wire [31:0] reg1_i,
    input wire [31:0] reg2_i,
    input wire [4:0] wd_i,
    input wire wreg_i,

    // �ӳٲ����?
    input wire [31:0] link_address_i,
    input wire is_in_delayslot_i,    

    // ����/�洢ָ��
    input wire [31:0] inst_i,
    output reg [4:0] wd_o,
    output reg wreg_o,
    output reg [31:0] wdata_o,

    // �ô�������
    output wire [4:0] aluop_o,
    output wire [31:0] mem_addr_o,
    output wire [31:0] reg2_o,
    
    output reg stall 
);
    // �ڲ��źŶ���
    reg [31:0] logicout, shiftres, arithmeticres;
    reg [63:0] mulres;
    wire [31:0] reg2_i_sign;
    wire [31:0] result_sum;
    wire [63:0] hilo_temp;
    wire [31:0] opdata1_mult, opdata2_mult;
    //wire overflow_flag;

    // �ô���������ֵ
    assign aluop_o = aluop_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
    assign reg2_o = reg2_i;
    
    // ��������
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

    always @(*) begin
        mulres = (rst == `RstEnable) ? 64'd0 :
            (aluop_i == `MUL_OP) ? hilo_temp : 64'd0;
    end

    mult_gen_0 mult_gen_0(
        .A(opdata1_mult),
        .B(opdata2_mult),
        .P(hilo_temp)
    );

    // // �˷�����
    // assign opdata1_mult = ((aluop_i ==  `MUL_OP) && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
    // assign opdata2_mult = ((aluop_i ==  `MUL_OP) && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;
    // //assign hilo_temp = opdata1_mult*opdata2_mult  ;
    // always @(*) begin
    //     mulres = (rst == `RstEnable) ? 64'd0 :
    //         (aluop_i ==  `MUL_OP) ? ((reg1_i[31] ^ reg2_i[31]) ? (~hilo_temp + 1) : hilo_temp) : hilo_temp;
    // end

	// //����ʿ��ʵ�ֳ˷���
    // wallace wallace_0(
    //     .mul1(opdata1_mult),
    //     .mul2(opdata2_mult),
    //     .result(hilo_temp)
    // );

    // // ������ˮ�߳˷���
    // reg [31:0] mul_op1, mul_op2;
    // reg mul_sign;
    // reg [1:0] mul_state;
    // reg [63:0] hilo_temp;

    // always @(posedge clk or posedge rst) begin
    //     if (rst == `RstEnable) begin
    //         mul_op1 <= 32'b0;
    //         mul_op2 <= 32'b0;
    //         mul_sign <= 1'b0;
    //         mul_state <= 2'b00;
    //         mul_ready <= 1'b0;
    //         mul_result <= 64'b0;
    //     end else begin
    //         case (mul_state)
    //             2'b00: begin  // ��ʼ״̬
    //                 if (aluop_i == `MUL_OP) begin
    //                     mul_op1 <= opdata1_mult;
    //                     mul_op2 <= opdata2_mult;
    //                     mul_sign <= reg1_i[31] ^ reg2_i[31];
    //                     mul_state <= 2'b01;
    //                     mul_ready <= 1'b0;
    //                 end
    //             end
    //             2'b01: begin  // ��һ����ˮ��
    //                 hilo_temp <= mul_op1 * mul_op2;
    //                 mul_state <= 2'b10;
    //             end
    //             2'b10: begin  // �ڶ�����ˮ��
    //                 mul_result <= mul_sign ? (~hilo_temp + 1) : hilo_temp;
    //                 mul_ready <= 1'b1;
    //                 mul_state <= 2'b00;
    //             end
    //         endcase
    //     end
    // end

    // ���ѡ��?
    always @(*) begin
        wd_o = wd_i;
        wreg_o = wreg_i;
        stall = `NoStop;
        case (alusel_i)
             `RES_LOGIC: 		wdata_o = logicout;
             `RES_SHIFT: 		wdata_o = shiftres;
             `RES_ARITHMETIC: 	wdata_o = arithmeticres;
             `RES_MUL: 			wdata_o = mulres[31:0];
             `RES_JUMP_BRANCH: 	wdata_o = link_address_i;
            default: 			wdata_o = `ZeroWord;
        endcase
    end

endmodule