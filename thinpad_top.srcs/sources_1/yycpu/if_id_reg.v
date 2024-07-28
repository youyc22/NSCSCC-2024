//if/id�׶μĴ�??

`include "defines.v"

module if_id_reg(
	input wire										clk,
	input wire										rst,
	input wire[5:0]                            		stall,

	input wire[31:0]								if_pc_i,		//if�׶ε�pc
	input wire[31:0]          						if_inst_i,		//if�׶ε�ָ??
	output reg[31:0]      							id_pc_o,		//id�׶ε�pc
	output reg[31:0]          						id_inst_o  		//id�׶ε�ָ??

);

	wire flush = rst | (stall[1] & ~stall[2]);

	always @ (posedge clk) begin
		if (flush) begin
			id_pc_o <= `ZeroWord;
			id_inst_o <= `ZeroWord;
		end else  if(stall[1]==`NoStop) begin
			id_pc_o <= if_pc_i;
			id_inst_o <= if_inst_i;
		end
	end

endmodule