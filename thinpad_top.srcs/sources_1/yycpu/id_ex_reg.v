`include "defines.v"

module id_ex_reg(
    input wire                     clk,
    input wire                     rst,
    input wire[5:0]                stall,

    //来自译码阶段的信息
    input wire[4:0]                id_aluop_i,
    input wire[2:0]                id_alusel_i,
    input wire[31:0]               id_reg1_i,
    input wire[31:0]               id_reg2_i,
    input wire[4:0]                id_wd_i,
    input wire                     id_wreg_i,

    input wire[31:0]               id_link_address_i,
    input wire[31:0]               id_inst_i,//指令

    //传递到执行阶段的信息
    output reg[4:0]                ex_aluop_o,
    output reg[2:0]                ex_alusel_o,
    output reg[31:0]               ex_reg1_o,
    output reg[31:0]               ex_reg2_o,
    output reg[4:0]                ex_wd_o,
    output reg                     ex_wreg_o,

    output reg[31:0]               ex_link_address_o,
    output reg[31:0]               ex_inst_o//指令
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || (stall[2] == `Stop && stall[3] == `NoStop)) begin
            ex_aluop_o <= `NOP_OP;
            ex_alusel_o <= `RES_NOP;
            ex_reg1_o <= `ZeroWord;
            ex_reg2_o <= `ZeroWord;
            ex_wd_o <= 5'b00000;
            ex_wreg_o <= `WriteDisable;
            ex_link_address_o <= `ZeroWord;
            ex_inst_o <= `ZeroWord;
        end else if(stall[2] == `NoStop) begin
            ex_aluop_o <= id_aluop_i;
            ex_alusel_o <= id_alusel_i;
            ex_reg1_o <= id_reg1_i;
            ex_reg2_o <= id_reg2_i;
            ex_wd_o <= id_wd_i;
            ex_wreg_o <= id_wreg_i;
            ex_link_address_o <= id_link_address_i;
            ex_inst_o <= id_inst_i;
        end
    end

endmodule