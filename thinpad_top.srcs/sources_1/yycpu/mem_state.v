module mem_state(
	input wire						rst,
	
	//����ִ�н׶ε���Ϣ	
	input wire[4:0]       			wd_i,
	input wire                    	wreg_i,
	input wire[31:0]				wdata_i,

	//�ô�
	input wire[4:0]        			aluop_i,
	input wire[31:0]          		mem_addr_i,
	input wire[31:0]          		reg2_i,
	input wire[31:0]          		mem_data_i,
	
	//�͵���д�׶ε���Ϣ
	output reg[4:0]      			wd_o,
	output reg                   	wreg_o,
	output reg[31:0]			 	wdata_o,
	
	//�ô�
	output reg[31:0]          		mem_addr_o,
	output reg[31:0]          		mem_data_o,
	output reg					 	mem_we_n,		//дʹ�ܣ���λ��Ч
	output reg[3:0]              	mem_be_n,		//�ֽ�ѡ�񣬵�λ��Ч
	output reg                   	mem_ce_n,		//��λ��Ч
	output reg                  	mem_oe_n 		//��ʹ�ܣ���λ��Ч
);
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= 5'b00000;
			wreg_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
			mem_we_n <= 1'b1;
			mem_oe_n <= 1'b1;
			mem_addr_o <= `ZeroWord;
			mem_be_n <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_n <= 1'b1;	
		end else begin
		  	wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_we_n <= 1'b1;
			mem_oe_n <= 1'b1;
			mem_addr_o <= `ZeroWord;
			mem_be_n <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_n <= 1'b1;
			case (aluop_i)
			 `LW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we_n <= 1'b1;
					mem_oe_n <= 1'b0;
					wdata_o <= mem_data_i;
					mem_be_n <= 4'b0000;
					mem_ce_n <= 1'b0;		
				end
             `SW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we_n <= 1'b0;
					mem_oe_n <= 1'b1;
					mem_data_o <= reg2_i;
					mem_be_n <= 4'b0000;	
					mem_ce_n <= 1'b0;		
				end
             `LB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we_n <= 1'b1;
					mem_oe_n <= 1'b0;
					mem_ce_n <= 1'b0;
					case (mem_addr_i[1:0])
                        2'b11: {wdata_o, mem_be_n} <= {{{24{mem_data_i[31]}}, mem_data_i[31:24]}, 4'b0111};
                        2'b10: {wdata_o, mem_be_n} <= {{{24{mem_data_i[23]}}, mem_data_i[23:16]}, 4'b1011};
                        2'b01: {wdata_o, mem_be_n} <= {{{24{mem_data_i[15]}}, mem_data_i[15:8]}, 4'b1101};
                        2'b00: {wdata_o, mem_be_n} <= {{{24{mem_data_i[7]}}, mem_data_i[7:0]}, 4'b1110};
                        default: wdata_o = `ZeroWord;
                    endcase
				end
			 `SB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we_n <= 1'b0;
					mem_oe_n <= 1'b1;
					mem_data_o <= {4{reg2_i[7:0]}};
					mem_ce_n <= 1'b0;
					case (mem_addr_i[1:0])
                        2'b11: 		mem_be_n <= 4'b0111;
                        2'b10: 		mem_be_n <= 4'b1011;
                        2'b01: 		mem_be_n <= 4'b1101;
                        2'b00: 		mem_be_n <= 4'b1110;
                        default: 	mem_be_n <= 4'b1111;
                    endcase			
				end
           	default:begin    
		   	end
			endcase		
		end    
	end      
			
endmodule