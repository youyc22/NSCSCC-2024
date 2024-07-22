//if/id阶段寄存??

`include "defines.v"

module if_id_reg(
	input wire										clk,
	input wire										rst,
	input wire[5:0]                            		stall,

	input wire[31:0]								if_pc_i,		//if阶段的pc
	input wire[31:0]          						if_inst_i,	//if阶段的指??
	output reg[31:0]      							id_pc_o,		//id阶段的pc
	output reg[31:0]          						id_inst_o  	//id阶段的指??

	//  // 新增：来自IF阶段的预测信??
    // input wire                                      if_prediction_taken,
    // input wire[31:0]                        if_prediction_target,
	// // 新增：传递给ID阶段的预测信??
    // output reg                                      id_prediction_taken,
    // output reg[31:0]                        id_prediction_target
);

	wire flush = rst | (stall[1] & ~stall[2]);

	always @ (posedge clk) begin
		if (flush) begin
			id_pc_o <= `ZeroWord;
			id_inst_o <= `ZeroWord;
			// id_prediction_taken <= 1'b0;
            // id_prediction_target <= `ZeroWord;
		end else  if(stall[1]==`NoStop) begin
			id_pc_o <= if_pc_i;
			id_inst_o <= if_inst_i;
			// id_prediction_taken <= if_prediction_taken;
            // id_prediction_target <= if_prediction_target;
		end
	end

endmodule