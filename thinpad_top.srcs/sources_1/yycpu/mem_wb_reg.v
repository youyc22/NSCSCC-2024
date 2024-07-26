`include "defines.v"

module mem_wb_reg(
    input wire                     clk,
    input wire                     rst,
    input wire[5:0]                stall,

    input wire[4:0]                mem_wd_i,
    input wire                     mem_wreg_i,
    input wire[31:0]               mem_wdata_i,
    
    output reg[4:0]                wb_wd_o,
    output reg                     wb_wreg_o,
    output reg[31:0]               wb_wdata_o
);

    always @ (posedge clk) begin
        if(rst == `RstEnable || (stall[4] == `Stop && stall[5] == `NoStop)) begin
            wb_wd_o <= 5'b00000;
            wb_wreg_o <= `WriteDisable;
            wb_wdata_o <= `ZeroWord;
        end else if(stall[4] == `NoStop) begin
            wb_wd_o <= mem_wd_i;
            wb_wreg_o <= mem_wreg_i;
            wb_wdata_o <= mem_wdata_i;
        end
    end
endmodule