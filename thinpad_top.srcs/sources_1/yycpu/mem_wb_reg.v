`include "defines.v"

module mem_wb_reg(
	input wire										clk,
	input wire										rst,
	
    input wire[5:0]               					stall,

	input wire[4:0]       							mem_wd,
	input wire                    					mem_wreg,
	input wire[31:0]					 			mem_wdata,

	output reg[4:0]      							wb_wd,
	output reg                   					wb_wreg,
	output reg[31:0]								wb_wdata	       
	
);

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= 5'b00000;
			wb_wreg <= `WriteDisable;
		  	wb_wdata <= `ZeroWord;	
		end else begin
			if(stall[4] == `Stop && stall[5] == `NoStop) begin
				wb_wd <= 5'b00000;
				wb_wreg <= `WriteDisable;
				wb_wdata <= `ZeroWord;		  	  
			end else if(stall[4] == `NoStop) begin
				wb_wd <= mem_wd;
				wb_wreg <= mem_wreg;
				wb_wdata <= mem_wdata;	
			end 
		end    
	end      
   
			
endmodule