`include "defines.v"

module if_state(
    input wire          clk,
    input wire          rst,
    input wire [5:0]    stall,

    input wire          branch_flag_i,
    input wire [31:0]   branch_address_i,
    output reg [31:0]   if_pc_o,
    output reg          rom_ce_n_o
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            rom_ce_n_o <= 1'b1;
            if_pc_o <= 32'h80000000;
        end else begin
            rom_ce_n_o <= 1'b0;
            if (~rom_ce_n_o && stall[0] == `NoStop) begin
                if_pc_o <= branch_flag_i ? branch_address_i : if_pc_o + 4'h4;
            end
        end
    end

endmodule