`include "defines.v"

module id_state(
	input wire									rst,
	//??if??ν???????
	input wire[31:0]					        id_pc_i,
	input wire[31:0]          				    id_inst_i,
	
	//????Load???
	input wire[4:0]								ex_aluop_i,
	
    //regfile????????
	input wire[31:0]           				    r1_data_i,
	input wire[31:0]           				    r2_data_i,

    //???????
    //??н?????????
	input wire									ex_we_i,
	input wire[31:0]							ex_wdata_i,
	input wire[4:0]            			        ex_waddr_i,
	
	//????????????
	input wire									mem_we_i,
	input wire[31:0]							mem_wdata_i,
	input wire[4:0]                  	        mem_waddr_i,

	//???regfile?????
	output reg                    				re1_o,
	output reg                    				re2_o,     
	output reg[4:0]       						r1_addr_o,
	output reg[4:0]       						r2_addr_o, 	      
	
	//?????н?ε????
	output reg[4:0]         					aluop_o,//5λ??????????
	output reg[2:0]        						alusel_o,//3λ????????
	output reg[31:0]           					r1_data_o,//???????1???
	output reg[31:0]           					r2_data_o,//???????2???
	output reg[4:0]       						waddr_o,//д?????
	output reg                   	 			we_o,//????д??
	
	output reg                    				branch_flag_o,
	output reg[31:0]           					branch_target_o,       
	output reg[31:0]           					link_o,

	output wire[31:0]          					inst_o,
	output wire        							stall_from_id    
);

	wire[5:0] 	op = id_inst_i[31:26];
	wire[4:0] 	rs = id_inst_i[25:21];
	wire[4:0] 	rt = id_inst_i[20:16];
	wire[4:0] 	rd = id_inst_i[15:11];
	wire[4:0] 	shamt = id_inst_i[10:6];
	wire[5:0] 	func = id_inst_i[5:0];
    wire 		is_inst_load;
	wire[31:0] 	pc_plus_8 = id_pc_i + 8;
	wire[31:0] 	pc_plus_4 = id_pc_i + 4;
	wire[31:0] 	branch_addr = pc_plus_4 + {{14{id_inst_i[15]}}, id_inst_i[15:0], 2'b00 };

    reg 		stall_for_reg1, stall_for_reg2;
	reg[31:0] 	imm_o;
	
    assign inst_o = id_inst_i;
    assign stall_from_id = stall_for_reg1 | stall_for_reg2;
    assign is_inst_load = (ex_aluop_i ==  `LW_OP) | (ex_aluop_i ==  `LB_OP);
      
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <=  `NOP_OP;
			alusel_o <=  `RES_NOP;
			waddr_o <= 5'b00000;
			we_o <= `WriteDisable;
			re1_o <= 1'b0;
			re2_o <= 1'b0;
			r1_addr_o <= 5'b00000;
			r2_addr_o <= 5'b00000;
			imm_o <= `ZeroWord;		
			link_o <= `ZeroWord;
			branch_target_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
	  	end else begin
			aluop_o <=  `NOP_OP;
			alusel_o <=  `RES_NOP;
			waddr_o <= rd;
			we_o <= `WriteDisable;  
			re1_o <= 1'b0;
			re2_o <= 1'b0;
			r1_addr_o <= rs;
			r2_addr_o <= rt;		
			imm_o <= `ZeroWord;			
			link_o <= `ZeroWord;
			branch_target_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;			
		case (op)
		 `R_INST:	begin
			case (func)
			`SRA:  		begin
				we_o <= `WriteEnable;    
				aluop_o <=  `SRA_OP;
				alusel_o <=  `RES_SHIFT;	
				re1_o <= 1'b0;	
				re2_o <= 1'b1;
				imm_o[4:0] <= shamt;
				end
			`SRL:       begin
				we_o <= `WriteEnable;		
				aluop_o <=  `SRL_OP;
				alusel_o <=  `RES_SHIFT; 
				re1_o <= 1'b0;	
				re2_o <= 1'b1;	  	
				imm_o[4:0] <= shamt;		
			end
			`SLL:       begin
				we_o <= `WriteEnable;		
				aluop_o <=  `SLL_OP;
				alusel_o <=  `RES_SHIFT; 
				re1_o <= 1'b0;	
				re2_o <= 1'b1;	  	
				imm_o[4:0] <= shamt;		
			end
			`SLT: 		begin
				we_o <= `WriteEnable;     
				aluop_o <=  `SLT_OP;
				alusel_o <=  `RES_ARITHMETIC;				
				re1_o <= 1'b1;	
				re2_o <= 1'b1;		    
				end
			`ADDU,`ADD: 		begin
				we_o <= `WriteEnable;		
				aluop_o <=  `ADDU_OP;
				alusel_o <=  `RES_ARITHMETIC;		
				re1_o <= 1'b1;	
				re2_o <= 1'b1;
				end
			`SUB,`SUBU:			begin
				we_o <= `WriteEnable;		
				aluop_o <=  `SUBU_OP;
				alusel_o <=  `RES_ARITHMETIC;		
				re1_o <= 1'b1;	
				re2_o <= 1'b1;
				end
			`OR:			begin
				we_o <= `WriteEnable;			
				aluop_o <=  `OR_OP;
				alusel_o <=  `RES_LOGIC; 	
				re1_o <= 1'b1;	
				re2_o <= 1'b1;	
				end  
			`AND:		begin
				we_o <= `WriteEnable;			
				aluop_o <=  `AND_OP;
				alusel_o <=  `RES_LOGIC;	  	
				re1_o <= 1'b1;	
				re2_o <= 1'b1;	
				end  	
			`XOR:		begin
				we_o <= `WriteEnable;			
				aluop_o <=  `XOR_OP;
				alusel_o <=  `RES_LOGIC;		
				re1_o <= 1'b1;	
				re2_o <= 1'b1;	
				end  	
			`JR: 		begin
				we_o <= `WriteDisable;			
				aluop_o <=  `JR_OP;
				alusel_o <=  `RES_JUMP_BRANCH;   
				re1_o <= 1'b1;	
				re2_o <= 1'b0;
				link_o <= `ZeroWord;	  						
				branch_target_o <= r1_data_o;
				branch_flag_o <= `Branch;			           
				end
			`JALR:	 	begin
				we_o <= `WriteEnable;			
				aluop_o <=  `JALR_OP;
				alusel_o <=  `RES_JUMP_BRANCH;   
				re1_o <= 1'b1;	
				re2_o <= 1'b0;	  						
				link_o <= pc_plus_8;
				branch_target_o <= r1_data_o;
				branch_flag_o <= `Branch;			           
				end
			default:		begin
				end
			endcase
		end
		`ORI:			 	begin                        
			we_o <= `WriteEnable;		
			aluop_o <=  `OR_OP;
			alusel_o <=  `RES_LOGIC; 
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			imm_o <= {16'h0, id_inst_i[15:0]};		
			waddr_o <= rt;
			end 	
		`LUI:			    begin
			we_o <= `WriteEnable;		
			aluop_o <=  `OR_OP;
			alusel_o <=  `RES_LOGIC; 
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			imm_o <= {id_inst_i[15:0], 16'h0};		
			waddr_o <= rt;		  		
			end	
		`ANDI:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `AND_OP;
			alusel_o <=  `RES_LOGIC;	
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			imm_o <= {16'h0, id_inst_i[15:0]};		
			waddr_o <= rt;		  		
			end	 	
		`XORI:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `XOR_OP;
			alusel_o <=  `RES_LOGIC;	
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			imm_o <= {16'h0, id_inst_i[15:0]};		
			waddr_o <= rt;		  		
			end	 	
		`ADDIU,`ADDI:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `ADDU_OP;
			alusel_o <=  `RES_ARITHMETIC; 
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			imm_o <= {{16{id_inst_i[15]}}, id_inst_i[15:0]};		
			waddr_o <= rt;		  		
			end
		`J:					begin
			we_o <= `WriteDisable;		
			aluop_o <=  `J_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			re1_o <= 1'b0;	
			re2_o <= 1'b0;
			link_o <= `ZeroWord;
			branch_target_o <= {pc_plus_4[31:28], id_inst_i[25:0], 2'b00};
			branch_flag_o <= `Branch;  		
			end
		`JAL:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `JAL_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			re1_o <= 1'b0;	
			re2_o <= 1'b0;
			waddr_o <= 5'b11111;	
			link_o <= pc_plus_8 ;
			branch_target_o <= {pc_plus_4[31:28], id_inst_i[25:0], 2'b00};
			branch_flag_o <= `Branch;	  		
			end
		`BEQ:				begin
			we_o <= `WriteDisable;		
			aluop_o <=  `BEQ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			re1_o <= 1'b1;	
			re2_o <= 1'b1;
			if(r1_data_o == r2_data_o) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;	  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
			end
			end
		`BNE:				begin
			we_o <= `WriteDisable;		
			aluop_o <=  `BLEZ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			re1_o <= 1'b1;	
			re2_o <= 1'b1;
			if(r1_data_o != r2_data_o) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;	  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
			end
			end	
		`BGTZ:				begin
			we_o <= `WriteDisable;		
			aluop_o <=  `BGTZ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			re1_o <= 1'b1;	
			re2_o <= 1'b0;
			if((r1_data_o[31] == 1'b0) && (r1_data_o != `ZeroWord)) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;	  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
			end
			end		
		`MUL:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `MUL_OP;
			alusel_o <=  `RES_MUL; 
			re1_o <= 1'b1;	
			re2_o <= 1'b1;	  			  
			end			
		`LW:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `LW_OP;
			alusel_o <=  `RES_LOAD_STORE;
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			waddr_o <= rt; 
			end
		`SW:				begin
			we_o <= `WriteDisable;		
			aluop_o <=  `SW_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			re1_o <= 1'b1;	
			re2_o <= 1'b1;
			end		
		`LB:				begin
			we_o <= `WriteEnable;		
			aluop_o <=  `LB_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			re1_o <= 1'b1;	
			re2_o <= 1'b0;	  	
			waddr_o <= rt; 
			end
		`SB:				begin
			we_o <= `WriteDisable;		
			aluop_o <=  `SB_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			re1_o <= 1'b1;	
			re2_o <= 1'b1; 
			end			 
		default:			begin
		end
		endcase		    
		end       
	end         
	
	always @ (*) begin
		stall_for_reg1 <= `NoStop;
		if(rst == `RstEnable) begin
			r1_data_o <= `ZeroWord;
		end else if((is_inst_load == 1'b1) && (ex_waddr_i == r1_addr_o) && (re1_o == 1'b1)) begin //load
		  	stall_for_reg1 <= `Stop;	
        end else if((re1_o == 1'b1) && (ex_we_i == 1'b1) && (ex_waddr_i == r1_addr_o) && (ex_waddr_i != 5'b0)) begin //ex??????????
        	r1_data_o <= ex_wdata_i; 
      	end else if((re1_o == 1'b1) && (mem_we_i == 1'b1) && (mem_waddr_i == r1_addr_o) && (mem_waddr_i != 5'b0)) begin //mem??????????
        	r1_data_o <= mem_wdata_i; 	
	  	end else if(re1_o == 1'b1) begin
	  		r1_data_o <= r1_data_i;
	  	end else if(re1_o == 1'b0) begin
	  		r1_data_o <= imm_o;
	 	end else begin
	    	r1_data_o <= `ZeroWord;
	 	end
	end
	
	always @ (*) begin
		stall_for_reg2 <= `NoStop;
		if(rst == `RstEnable) begin
			r2_data_o <= `ZeroWord;
		end else if(is_inst_load == 1'b1 && ex_waddr_i == r2_addr_o && re2_o == 1'b1 ) begin
		  	stall_for_reg2 <= `Stop;	
		end else if((re2_o == 1'b1) && (ex_we_i == 1'b1) && (ex_waddr_i == r2_addr_o) && (ex_waddr_i != 5'b0)) begin
			r2_data_o <= ex_wdata_i; 
		end else if((re2_o == 1'b1) && (mem_we_i == 1'b1) && (mem_waddr_i == r2_addr_o) && (mem_waddr_i != 5'b0)) begin
			r2_data_o <= mem_wdata_i;		
		end else if(re2_o == 1'b1) begin
			r2_data_o <= r2_data_i;
		end else if(re2_o == 1'b0) begin
			r2_data_o <= imm_o;
		end else begin
			r2_data_o <= `ZeroWord;
		end
	end

endmodule