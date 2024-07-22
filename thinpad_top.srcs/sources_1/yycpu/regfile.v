`include "defines.v"

module regfile(
	input wire										clk,
	input wire										rst,
	
	// Ğ´¶Ë¿Ú
	input wire										reg_we,
	input wire[4:0]									reg_w_addr,
	input wire[31:0]								reg_w_data,
	
	// ¶Á¶Ë¿Ú1
	input wire										reg_re1,
	input wire[4:0]			  						reg_r_addr1,
	output reg[31:0]           						reg_r_data1,
	
	// ¶Á¶Ë¿Ú2
	input wire										reg_re2,
	input wire[4:0]			  						reg_r_addr2,
	output reg[31:0]           						reg_r_data2
	
);

	reg[31:0]  regs[0:31];
	
    //§Õ??
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((reg_we == `WriteEnable) && (reg_w_addr != 5'h0)) begin
				regs[reg_w_addr] <= reg_w_data;
			end else if(reg_w_addr == 5'h0) begin
			    regs[reg_w_addr] <= `ZeroWord;
		    end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg_r_data1 <= `ZeroWord;
		end else if(reg_r_addr1 == 5'h0) begin //rs1=x0
			reg_r_data1 <= `ZeroWord;
		end else if((reg_r_addr1 == reg_w_addr) && (reg_we == `WriteEnable) && (reg_re1 == `ReadEnable)) begin //??§Õ???
			reg_r_data1 <= reg_w_data;
		end else if(reg_re1 == `ReadEnable) begin
			reg_r_data1 <= regs[reg_r_addr1];
		end else begin
			reg_r_data1 <= `ZeroWord;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			reg_r_data2 <= `ZeroWord;
		end else if(reg_r_addr2 == 5'h0) begin
			reg_r_data2 <= `ZeroWord;
		end else if((reg_r_addr2 == reg_w_addr) && (reg_we == `WriteEnable) && (reg_re2 == `ReadEnable)) begin
			reg_r_data2 <= reg_w_data;
		end else if(reg_re2 == `ReadEnable) begin
			reg_r_data2 <= regs[reg_r_addr2];
		end else begin
			reg_r_data2 <= `ZeroWord;
		end
	end
	
endmodule