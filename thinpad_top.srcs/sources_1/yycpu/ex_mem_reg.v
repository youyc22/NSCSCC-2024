`include "defines.v"

module ex_mem_reg(
    input wire                 clk,
    input wire                 rst,
    input wire[5:0]            stall,

    // 来自执行阶段的信息
    input wire[4:0]            ex_wd,
    input wire                 ex_wreg,
    input wire[31:0]           ex_wdata,

    // 传递
    input wire[4:0]            ex_aluop,
    input wire[31:0]           ex_mem_addr,
    input wire[31:0]           ex_reg2,

    // 传到访存阶段的信息
    output reg[4:0]            mem_wd,
    output reg                 mem_wreg,
    output reg[31:0]           mem_wdata,

    // 传递
    output reg[4:0]            mem_aluop,
    output reg[31:0]           mem_mem_addr,
    output reg[31:0]           mem_reg2
);

    always @ (posedge clk) begin
        if(rst == `RstEnable || (stall[3] == `Stop && stall[4] == `NoStop)) begin
            mem_wd <= 5'b00000;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_aluop <=  `NOP_OP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
        end else if(stall[3] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
            mem_aluop <= ex_aluop;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;
        end
    end

endmodule