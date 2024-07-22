`include "defines.v"


module id_state(
	input wire									rst,
	//??if??ν???????
	input wire[31:0]					        pc_i,
	input wire[31:0]          				    inst_i,
	
	//????Load???
	input wire[4:0]								ex_aluop_i,
	
    //regfile????????
	input wire[31:0]           				    reg1_data_i,
	input wire[31:0]           				    reg2_data_i,

    //???????
    //??н?????????
	input wire									ex_wreg_i,
	input wire[31:0]							ex_wdata_i,
	input wire[4:0]            			        ex_wd_i,
	
	//????????????
	input wire									mem_wreg_i,
	input wire[31:0]							mem_wdata_i,
	input wire[4:0]                  	        mem_wd_i,
	
    //????
    input wire                    				is_in_delayslot_i,

	//???regfile?????
	output reg                    				reg1_read_o,
	output reg                    				reg2_read_o,     
	output reg[4:0]       						reg1_addr_o,
	output reg[4:0]       						reg2_addr_o, 	      
	
	//?????н?ε????
	output reg[4:0]         					aluop_o,//5λ??????????
	output reg[2:0]        						alusel_o,//3λ????????
	output reg[31:0]           					reg1_o,//???????1???
	output reg[31:0]           					reg2_o,//???????2???
	output reg[4:0]       						waddr_o,//д?????
	output reg                   	 			wreg_o,//????д??
	
	//????
	output reg                   				next_inst_in_delayslot_o,
	
	output reg                    				branch_flag_o,
	output reg[31:0]           					branch_target_o,       
	output reg[31:0]           					link_addr_o,
	output reg                    				is_in_delayslot_o,
	//ls
	output wire[31:0]          					inst_o,
	output wire        							stall    
);

	wire[5:0] op = inst_i[31:26];
	wire[4:0] rs = inst_i[25:21];
	wire[4:0] rt = inst_i[20:16];
	wire[4:0] rd = inst_i[15:11];
	wire[4:0] shamt = inst_i[10:6];
	wire[5:0] func = inst_i[5:0];
		
	reg[31:0] imm_o;

	//????
	wire[31:0] pc_plus_8 = pc_i + 8;
	wire[31:0] pc_plus_4 = pc_i + 4;
	wire[31:0] branch_addr = pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };

    //????load???
    reg stall_for_reg1_load, stall_for_reg2_load;
    wire pre_inst_is_load;
	
    //ls
    assign inst_o = inst_i;

  	//????????
    assign stall = stall_for_reg1_load | stall_for_reg2_load;
    assign pre_inst_is_load = (ex_aluop_i ==  `LW_OP)||(ex_aluop_i ==  `LB_OP)  ? 1'b1 : 1'b0;
      
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <=  `NOP_OP;
			alusel_o <=  `RES_NOP;
			waddr_o <= 5'b00000;
			wreg_o <= `WriteDisable;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= 5'b00000;
			reg2_addr_o <= 5'b00000;
			imm_o <= `ZeroWord;		
			link_addr_o <= `ZeroWord;
			branch_target_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;	
	  	end else begin
			aluop_o <=  `NOP_OP;
			alusel_o <=  `RES_NOP;
			waddr_o <= rd;
			wreg_o <= `WriteDisable;  
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= rs;
			reg2_addr_o <= rt;		
			imm_o <= `ZeroWord;			
			link_addr_o <= `ZeroWord;
			branch_target_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;			
			next_inst_in_delayslot_o <= `NotInDelaySlot; 
		case (op)
		 `SPECIAL_INST:	begin
			case (func)
			`SRA:  		begin
				wreg_o <= `WriteEnable;    
				aluop_o <=  `SRA_OP;
				alusel_o <=  `RES_SHIFT;	
				reg1_read_o <= 1'b0;	
				reg2_read_o <= 1'b1;
				imm_o <= {27'b0, shamt};
				end
			`SRL:       begin
				wreg_o <= `WriteEnable;		
				aluop_o <=  `SRL_OP;
				alusel_o <=  `RES_SHIFT; 
				reg1_read_o <= 1'b0;	
				reg2_read_o <= 1'b1;	  	
				imm_o[4:0] <= shamt;		
			end
			`SLL:       begin
				wreg_o <= `WriteEnable;		
				aluop_o <=  `SLL_OP;
				alusel_o <=  `RES_SHIFT; 
				reg1_read_o <= 1'b0;	
				reg2_read_o <= 1'b1;	  	
				imm_o[4:0] <= shamt;		
			end
			`SLT: 		begin
				wreg_o <= `WriteEnable;     
				aluop_o <=  `SLT_OP;
				alusel_o <=  `RES_ARITHMETIC;				
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;		    
				end
			`ADDU,`ADD: 		begin
				wreg_o <= `WriteEnable;		
				aluop_o <=  `ADDU_OP;
				alusel_o <=  `RES_ARITHMETIC;		
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;
				end
			`SUB,`SUBU:			begin
				wreg_o <= `WriteEnable;		
				aluop_o <=  `SUBU_OP;
				alusel_o <=  `RES_ARITHMETIC;		
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;
				end
			`OR:			begin
				wreg_o <= `WriteEnable;			
				aluop_o <=  `OR_OP;
				alusel_o <=  `RES_LOGIC; 	
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;	
				end  
			`AND:		begin
				wreg_o <= `WriteEnable;			
				aluop_o <=  `AND_OP;
				alusel_o <=  `RES_LOGIC;	  	
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;	
				end  	
			`XOR:		begin
				wreg_o <= `WriteEnable;			
				aluop_o <=  `XOR_OP;
				alusel_o <=  `RES_LOGIC;		
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b1;	
				end  	
			`JR: 		begin
				wreg_o <= `WriteDisable;			
				aluop_o <=  `JR_OP;
				alusel_o <=  `RES_JUMP_BRANCH;   
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b0;
				link_addr_o <= `ZeroWord;	  						
				branch_target_o <= reg1_o;
				branch_flag_o <= `Branch;			           
				next_inst_in_delayslot_o <= `InDelaySlot;	
				end
			`JALR:	 	begin
				wreg_o <= `WriteEnable;			
				aluop_o <=  `JALR_OP;
				alusel_o <=  `RES_JUMP_BRANCH;   
				reg1_read_o <= 1'b1;	
				reg2_read_o <= 1'b0;	  						
				link_addr_o <= pc_plus_8;
				branch_target_o <= reg1_o;
				branch_flag_o <= `Branch;			           
				next_inst_in_delayslot_o <= `InDelaySlot;
				end
			default:		begin
				end
			endcase
		end
		`ORI:			 	begin                        
			wreg_o <= `WriteEnable;		
			aluop_o <=  `OR_OP;
			alusel_o <=  `RES_LOGIC; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			imm_o <= {16'h0, inst_i[15:0]};		
			waddr_o <= rt;
			end 	
		`LUI:			    begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `OR_OP;
			alusel_o <=  `RES_LOGIC; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			imm_o <= {inst_i[15:0], 16'h0};		
			waddr_o <= rt;		  		
			end	
		`ANDI:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `AND_OP;
			alusel_o <=  `RES_LOGIC;	
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			imm_o <= {16'h0, inst_i[15:0]};		
			waddr_o <= rt;		  		
			end	 	
		`XORI:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `XOR_OP;
			alusel_o <=  `RES_LOGIC;	
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			imm_o <= {16'h0, inst_i[15:0]};		
			waddr_o <= rt;		  		
			end	 	
		`ADDIU,`ADDI:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `ADDU_OP;
			alusel_o <=  `RES_ARITHMETIC; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			imm_o <= {{16{inst_i[15]}}, inst_i[15:0]};		
			waddr_o <= rt;		  		
			end
		`J:					begin
			wreg_o <= `WriteDisable;		
			aluop_o <=  `J_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			reg1_read_o <= 1'b0;	
			reg2_read_o <= 1'b0;
			link_addr_o <= `ZeroWord;
			branch_target_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			branch_flag_o <= `Branch;
			next_inst_in_delayslot_o <= `InDelaySlot;		  		
			end
		`JAL:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `JAL_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			reg1_read_o <= 1'b0;	
			reg2_read_o <= 1'b0;
			waddr_o <= 5'b11111;	
			link_addr_o <= pc_plus_8 ;
			branch_target_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			branch_flag_o <= `Branch;
			next_inst_in_delayslot_o <= `InDelaySlot;		  		
			end
		`BEQ:				begin
			wreg_o <= `WriteDisable;		
			aluop_o <=  `BEQ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b1;
			if(reg1_o == reg2_o) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;
				next_inst_in_delayslot_o <= `InDelaySlot;		  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
				next_inst_in_delayslot_o <= `NotInDelaySlot; 
			end
			end
		`BNE:				begin
			wreg_o <= `WriteDisable;		aluop_o <=  `BLEZ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			if(reg1_o != reg2_o) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;
				next_inst_in_delayslot_o <= `InDelaySlot;		  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
				next_inst_in_delayslot_o <= `NotInDelaySlot; 
			end
			end	
		`BGTZ:				begin
			wreg_o <= `WriteDisable;		
			aluop_o <=  `BGTZ_OP;
			alusel_o <=  `RES_JUMP_BRANCH; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;
			if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
				branch_target_o <= branch_addr;
				branch_flag_o <= `Branch;
				next_inst_in_delayslot_o <= `InDelaySlot;		  	
			end else begin
				branch_target_o <= `ZeroWord;
				branch_flag_o <= `NotBranch;	
				next_inst_in_delayslot_o <= `NotInDelaySlot; 
			end
			end		
		`MUL:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `MUL_OP;
			alusel_o <=  `RES_MUL; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b1;	  			  
			end			
		`LW:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `LW_OP;
			alusel_o <=  `RES_LOAD_STORE;
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			waddr_o <= rt; 
			end
		`SW:				begin
			wreg_o <= `WriteDisable;		
			aluop_o <=  `SW_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b1;
			end		
		`LB:				begin
			wreg_o <= `WriteEnable;		
			aluop_o <=  `LB_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b0;	  	
			waddr_o <= rt; 
			end
		`SB:				begin
			wreg_o <= `WriteDisable;		
			aluop_o <=  `SB_OP;
			alusel_o <=  `RES_LOAD_STORE; 
			reg1_read_o <= 1'b1;	
			reg2_read_o <= 1'b1; 
			end			 
		default:			begin
		end
		endcase		    
		end       
	end         
	
	always @ (*) begin
		stall_for_reg1_load <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if((pre_inst_is_load == 1'b1) && (ex_wd_i == reg1_addr_o) && (reg1_read_o == 1'b1)) begin //load
		  	stall_for_reg1_load <= `Stop;	
        end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o) && (ex_wd_i != 5'b0)) begin //ex??????????
        	reg1_o <= ex_wdata_i; 
      	end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o) && (mem_wd_i != 5'b0)) begin //mem??????????
        	reg1_o <= mem_wdata_i; 	
	  	end else if(reg1_read_o == 1'b1) begin
	  		reg1_o <= reg1_data_i;
	  	end else if(reg1_read_o == 1'b0) begin
	  		reg1_o <= imm_o;
	 	end else begin
	    	reg1_o <= `ZeroWord;
	 	end
	end
	
	always @ (*) begin
		stall_for_reg2_load <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1 ) begin
		  	stall_for_reg2_load <= `Stop;	
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;		
		end else if(reg2_read_o == 1'b1) begin
			reg2_o <= reg2_data_i;
		end else if(reg2_read_o == 1'b0) begin
			reg2_o <= imm_o;
		end else begin
			reg2_o <= `ZeroWord;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
		  	is_in_delayslot_o <= is_in_delayslot_i;		
	  	end
	end

endmodule