`include "defines.v"

module stall_controller(
	input wire					 rst,
    input wire                   stall_from_bus,
	input wire                   stall_from_id,
	input wire                   stall_from_ex,
	input wire                   stall_from_mem,
	input wire                   stall_from_icache,
	output reg[5:0]              stall       
);

	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(stall_from_icache == `Stop ) begin
			stall <= 6'b111111;				
		end else if(stall_from_mem == `Stop) begin
			stall <= 6'b011111;
		end else if(stall_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stall_from_id == `Stop || stall_from_bus == `Stop) begin
			stall <= 6'b000111;				
		end else begin
			stall <= 6'b000000;
		end   
	end     
			
endmodule