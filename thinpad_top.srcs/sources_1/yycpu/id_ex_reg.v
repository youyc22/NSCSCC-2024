`include "defines.v"

module id_ex_reg(
	input wire					  	clk,
	input wire					  	rst,
	//������׶δ��ݵ���Ϣ
	input wire[4:0]         		id_aluop,
	input wire[2:0]        			id_alusel,
	input wire[31:0]           		id_reg1,
	input wire[31:0]           		id_reg2,
	input wire[4:0]       			id_wd,
	input wire                    	id_wreg,	
	input wire[5:0]				  	stall,
	//�ӳٲ�
	input wire[31:0]           		id_link_address,
	input wire                    	id_is_in_delayslot,
	input wire                    	next_inst_in_delayslot_i,		
	input wire[31:0]           		id_inst,//ָ��
	//���ݵ�ִ�н׶ε���Ϣ
	output reg[4:0]         		ex_aluop,
	output reg[2:0]        			ex_alusel,
	output reg[31:0]           		ex_reg1,
	output reg[31:0]           		ex_reg2,
	output reg[4:0]       			ex_wd,
	output reg                    	ex_wreg,
	//�ӳٲ�
	output reg[31:0]           		ex_link_address,
    output reg                    	ex_is_in_delayslot,
	output reg                    	is_in_delayslot_o,
	output reg [31:0]          		ex_inst//ָ��
);
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <=  `NOP_OP;
			ex_alusel <=  `RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= 5'b00000;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
	        is_in_delayslot_o <= `NotInDelaySlot;	
	        ex_inst <= `ZeroWord;
		end else begin
			if(stall[2] == `Stop && stall[3] == `NoStop) begin
				ex_aluop <=  `NOP_OP;
				ex_alusel <=  `RES_NOP;
				ex_reg1 <= `ZeroWord;
				ex_reg2 <= `ZeroWord;
				ex_wd <= 5'b00000;
				ex_wreg <= `WriteDisable;
				ex_link_address <= `ZeroWord;
				ex_is_in_delayslot <= `NotInDelaySlot;
				ex_inst <= `ZeroWord;	
			end else if(stall[2] == `NoStop) begin		
				ex_aluop <= id_aluop;
				ex_alusel <= id_alusel;
				ex_reg1 <= id_reg1;
				ex_reg2 <= id_reg2;
				ex_wd <= id_wd;
				ex_wreg <= id_wreg;	
				ex_link_address <= id_link_address;
				ex_is_in_delayslot <= id_is_in_delayslot;
				is_in_delayslot_o <= next_inst_in_delayslot_i;
				ex_inst <= id_inst;		
			end
		end
	end

endmodule