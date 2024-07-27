
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
		if(rst) 										stall <= 6'b000000;
 		else if(stall_from_icache || stall_from_mem) 	stall <= 6'b111111;				
		else if(stall_from_mem) 						stall <= 6'b111111;
		else if(stall_from_ex) 							stall <= 6'b001111;
		else if(stall_from_id || stall_from_bus) 		stall <= 6'b000111;				
		else 											stall <= 6'b000000;
	end     
			
endmodule