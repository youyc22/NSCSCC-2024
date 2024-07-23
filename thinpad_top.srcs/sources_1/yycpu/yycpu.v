`include "defines.v"

module yycpu(
	input wire						clk,		//???????
	input wire						rst,		//??¦Ë???

	input wire[31:0]            	rom_data_i,	//???????
	output wire[31:0]          		rom_addr_o,	//??????
	output wire                    	rom_ce_n,
	
	input wire                     	stall_from_bus,
	
	//????????
	input wire[31:0]            	ram_data_i,
	output wire[31:0]          		ram_addr_o,
	output wire[31:0]           	ram_data_o,
	output wire                    	ram_we_n,
	output wire[3:0]               	ram_be_n,
	output wire               		ram_ce_n,
	output wire						ram_oe_n
);

	wire[31:0] id_pc_i;
	wire[31:0] id_inst_i;
	
	//??????????ID?????????ID/EX??????????
	wire[4:0] id_aluop_o;
	wire[2:0] id_alusel_o;
	wire[31:0] id_reg1_o;
	wire[31:0] id_reg2_o;
	wire id_wreg_o;
	wire[4:0] id_wd_o;
	
	//???
	wire[31:0] id_inst_o;
	//????
	wire id_is_in_delayslot_o;
  	wire[31:0] id_link_address_o;
	
	//????ID/EX???????????§ß??EX??????????
	wire[4:0] ex_aluop_i;
	wire[2:0] ex_alusel_i;
	wire[31:0] ex_reg1_i;
	wire[31:0] ex_reg2_i;
	wire ex_wreg_i;
	wire[4:0] ex_wd_i;
	//????
	wire ex_is_in_delayslot_i;	
    wire[31:0] ex_link_address_i;
	//???
	wire[31:0] ex_inst_i;
	
	//??????§ß??EX?????????EX/MEM??????????
	wire ex_wreg_o;
	wire[4:0] ex_wd_o;
	wire[31:0] ex_wdata_o;

	//???
	wire[4:0] ex_aluop_o;
	wire[31:0] ex_mem_addr_o;
	wire[31:0] ex_reg1_o;
	wire[31:0] ex_reg2_o;

	//????EX/MEM?????????????MEM??????????
	wire mem_wreg_i;
	wire[4:0] mem_wd_i;
	wire[31:0] mem_wdata_i;

	//???
	wire[4:0] mem_aluop_i;
	wire[31:0] mem_mem_addr_i;
	wire[31:0] mem_reg1_i;
	wire[31:0] mem_reg2_i;	

	//????????MEM?????????MEM/WB??????????
	wire mem_wreg_o;
	wire[4:0] mem_wd_o;
	wire[31:0] mem_wdata_o;
	
	//????MEM/WB??????????§Õ??¦Å???????	
	wire wb_wreg_i;
	wire[4:0] wb_wd_i;
	wire[31:0] wb_wdata_i;
	
	//??????????ID???????¨¹????Regfile???
	wire reg1_read;
	wire reg2_read;
	wire[31:0] reg1_data;
	wire[31:0] reg2_data;
	wire[4:0] reg1_addr;
	wire[4:0] reg2_addr;
	
	//???
	wire[5:0] stall;
	wire stall_from_id;	
	wire stall_from_ex;
  
  	//????
  	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[31:0] branch_target_address;
	
	wire[31:0] rom_data_icache;
	wire stall_from_icache;
	wire [31:0]ram_data_cache_o;
	wire stall_from_dcache;

	if_state u_if_state(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),
		.if_pc(rom_addr_o),
		.ce_n_i(rom_ce_n)
	);

	icache_direct u_icache(
		.clk(clk),
		.rst(rst),
		.rom_addr_i(rom_addr_o),        //??????????
		.rom_ce_n_i(rom_ce_n),          //????????????????
		.inst_o(rom_data_icache),            //??????????
		.stall(stall_from_icache),
		.stall_from_bus(stall_from_bus),
		.inst_i(rom_data_i)          //??????????
	);

	if_id_reg u_if_id_reg(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.if_pc_i(rom_addr_o),
		.if_inst_i(rom_data_icache),
		.id_pc_o(id_pc_i),
		.id_inst_o(id_inst_i)      	
	);
	
	id_state u_id_state(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
        .ex_aluop_i(ex_aluop_o),
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
        //ex???
	   	.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		//mem???
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),
		//????
		.is_in_delayslot_i(is_in_delayslot_i),
		//???regfile?????
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
		//???ID/EX????????
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.waddr_o(id_wd_o),
		.wreg_o(id_wreg_o),
		//???
		.inst_o(id_inst_o),
		//????
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		.is_in_delayslot_o(id_is_in_delayslot_o),
		//???
		.stall(stall_from_id)	
	);

	regfile u_regfile(
		.clk (clk),
		.rst (rst),
		.reg_we	(wb_wreg_i),
		.reg_w_addr (wb_wd_i),
		.reg_w_data (wb_wdata_i),
		.reg_re1 (reg1_read),
		.reg_r_addr1 (reg1_addr),
		.reg_r_data1 (reg1_data),
		.reg_re2 (reg2_read),
		.reg_r_addr2 (reg2_addr),
		.reg_r_data2 (reg2_data)
	);

	id_ex_reg u_id_ex_reg(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_inst(id_inst_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_inst(ex_inst_i),
		.ex_link_address(ex_link_address_i),
    	.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i)	
	);		
	
	ex_state u_ex_state(
		.clk(clk),
		.rst(rst),
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
	  	.inst_i(ex_inst_i),
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),	
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),
		.stall(stall_from_ex)  
	);


    ex_mem_reg u_ex_mem_reg(
		.clk(clk),
		.rst(rst),
	  	.stall(stall),
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
	   	.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i)						       	
	);
	
  	//MEM???????
	mem_state u_mem_state(
		.rst(rst),
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	    .aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.mem_data_i(ram_data_cache_o),
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
        .mem_addr_o(ram_addr_o),
		.mem_data_o(ram_data_o),
		.mem_we_n(ram_we_n),
		.mem_be_n(ram_be_n),
		.mem_ce_n(ram_ce_n),
		.mem_oe_n(ram_oe_n)	
	);
	
	dcache_new u_dcache(
		.clk(clk),
		.rst(rst),
		.ram_data_o(ram_data_cache_o),        //?????????
		.mem_addr_i(ram_addr_o),        	  //????§Õ?????
		.mem_data_i(ram_data_o),              //§Õ?????????
		.mem_we_n_i(ram_we_n),          	  //§Õ????????§¹
		.mem_be_n_i(ram_be_n),         	  //??????????????§¹
		.mem_oe_n_i(ram_oe_n),          	  //??????????§¹
		.mem_ce_n_i(ram_ce_n),          	  //?????
		.stall(stall_from_dcache),
		.ram_data_i(ram_data_i)               //§Õ?????????
	);

	//MEM/WB???
	mem_wb_reg u_mem_wb_reg(
		.clk(clk),
		.rst(rst),
        .stall(stall),
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)											       	
	);
	
	stall_ctrl u_stall_ctrl(
		.rst(rst),	
		.stall_from_bus(stall_from_bus),
		.stall_from_id(stall_from_id),
		.stall_from_ex(stall_from_ex),
		.stall_from_dcache(stall_from_dcache),
		.stall_from_icache(stall_from_icache),
		.stall(stall)   	
	);

endmodule