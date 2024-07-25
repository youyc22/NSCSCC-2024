`include "defines.v"

module if_state(
    input wire clk,
    input wire rst,
    input wire [5:0] stall,
    input wire branch_flag_i,
    input wire [31:0] branch_target_address_i,
    output reg [31:0] if_pc,
    output reg rom_ce_n
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            rom_ce_n <= 1'b1;
            if_pc <= 32'h80000000;
        end else begin
            rom_ce_n <= 1'b0;
            if (~rom_ce_n && stall[0] == `NoStop) begin
                if_pc <= branch_flag_i ? branch_target_address_i : if_pc + 4'h4;
            end
        end
    end

endmodule