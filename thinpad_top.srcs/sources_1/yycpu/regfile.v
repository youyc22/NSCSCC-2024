`include "defines.v"

module regfile(
	input wire										clk,
	input wire										rst,
	
	// д�˿�
	input wire										reg_we_i,
	input wire[4:0]									reg_w_addr_i,
	input wire[31:0]								reg_w_data_i,
	
	// ���˿�1
	input wire										reg_re1_i,
	input wire[4:0]			  						reg_r_addr1_i,
	output reg[31:0]           						reg_r_data1_o,
	
	// ���˿�2
	input wire										reg_re2_i,
	input wire[4:0]			  						reg_r_addr2_i,
	output reg[31:0]           						reg_r_data2_o
	
);

	reg[31:0]  regs[0:31];
	
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((reg_we_i == `WriteEnable) && (reg_w_addr_i != 5'h0)) begin
				regs[reg_w_addr_i] <= reg_w_data_i;
			end else if(reg_w_addr_i == 5'h0) begin
			    regs[reg_w_addr_i] <= `ZeroWord;
		    end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			reg_r_data1_o <= `ZeroWord;
		end else if(reg_r_addr1_i == 5'h0) begin 
			reg_r_data1_o <= `ZeroWord;
		end else if((reg_r_addr1_i == reg_w_addr_i) && (reg_we_i == `WriteEnable) && (reg_re1_i == `ReadEnable)) begin //??��???
			reg_r_data1_o <= reg_w_data_i;
		end else if(reg_re1_i == `ReadEnable) begin
			reg_r_data1_o <= regs[reg_r_addr1_i];
		end else begin
			reg_r_data1_o <= `ZeroWord;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			reg_r_data2_o <= `ZeroWord;
		end else if(reg_r_addr2_i == 5'h0) begin
			reg_r_data2_o <= `ZeroWord;
		end else if((reg_r_addr2_i == reg_w_addr_i) && (reg_we_i == `WriteEnable) && (reg_re2_i == `ReadEnable)) begin
			reg_r_data2_o <= reg_w_data_i;
		end else if(reg_re2_i == `ReadEnable) begin
			reg_r_data2_o <= regs[reg_r_addr2_i];
		end else begin
			reg_r_data2_o <= `ZeroWord;
		end
	end
	
endmodule