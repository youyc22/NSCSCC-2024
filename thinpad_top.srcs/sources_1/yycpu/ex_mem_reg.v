`include "defines.v"

module ex_mem_reg(
    input wire                 clk,
    input wire                 rst,
    input wire[5:0]            stall,

    // 来自执行阶段的信息
    input wire[4:0]            ex_wd_i,
    input wire                 ex_wreg_i,
    input wire[31:0]           ex_wdata_i,
    input wire[4:0]            ex_aluop_i,
    input wire[31:0]           ex_mem_addr_i,
    input wire[31:0]           ex_reg2_i,

    // 传到访存阶段的信息
    output reg[4:0]            mem_wd_o,
    output reg                 mem_wreg_o,
    output reg[31:0]           mem_wdata_o,
    output reg[4:0]            mem_aluop_o,
    output reg[31:0]           mem_mem_addr_o,
    output reg[31:0]           mem_reg2_o
);

    always @ (posedge clk) begin
        if(rst == `RstEnable || (stall[3] == `Stop && stall[4] == `NoStop)) begin
            mem_wd_o <= 5'b00000;
            mem_wreg_o <= `WriteDisable;
            mem_wdata_o <= `ZeroWord;
            mem_aluop_o <=  `NOP_OP;
            mem_mem_addr_o <= `ZeroWord;
            mem_reg2_o <= `ZeroWord;
        end else if(stall[3] == `NoStop) begin
            mem_wd_o <= ex_wd_i;
            mem_wreg_o <= ex_wreg_i;
            mem_wdata_o <= ex_wdata_i;
            mem_aluop_o <= ex_aluop_i;
            mem_mem_addr_o <= ex_mem_addr_i;
            mem_reg2_o <= ex_reg2_i;
        end
    end

endmodule