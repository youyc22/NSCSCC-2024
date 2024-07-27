`include "defines.v"

module yycpu(
	input  wire						clk,		//???????
	input  wire						rst,		//??��???

	input  wire[31:0]            	rom_data_i,	//???????
	input  wire                     stall_from_bus,
	output wire[31:0]          		rom_addr_o,	//??????
	output wire                    	rom_ce_n_o,
	
	//????????
	input  wire[31:0]            	ram_data_i,
	output wire[31:0]          		ram_addr_o,
	output wire[31:0]           	ram_data_o,
	output wire                    	ram_we_n,
	output wire[3:0]               	ram_be_n,
	output wire               		ram_ce_n,
	output wire						ram_oe_n
);

	wire[31:0] id_pc, id_inst;

	//??????????ID?????????ID/EX??????????
	wire[4:0] 	id_aluop;
	wire[2:0] 	id_alusel;
	wire[31:0] 	id_reg1, id_reg2;
	wire 		id_we;
	wire[4:0] 	id_waddr;
	wire[31:0] 	id_inst_o;
  	wire[31:0] 	id_link_address_o;
	
	//????ID/EX???????????��??EX??????????
	wire[4:0] 	ex_aluop_i;
	wire[2:0] 	ex_alusel_i;
	wire[31:0] 	ex_reg1_i, ex_reg2_i;
	wire 		ex_wreg_i, ex_wreg_o;
	wire[4:0] 	ex_wd_i;
    wire[31:0] 	ex_link_address_i, ex_inst_i;
	wire[4:0] 	ex_wd_o;
	wire[31:0] 	ex_wdata_o;
	wire[4:0] 	ex_aluop_o;
	wire[31:0] 	ex_mem_addr_o;
	wire[31:0] 	ex_reg1_o, ex_reg2_o;

	//????EX/MEM?????????????MEM??????????
	wire 		mem_wreg_i;
	wire[4:0] 	mem_wd_i;
	wire[31:0] 	mem_wdata_i;

	//???
	wire[4:0] 	mem_aluop_i;
	wire[31:0] 	mem_mem_addr_i;
	wire[31:0] 	mem_reg1_i, mem_reg2_i;

	//????????MEM?????????MEM/WB??????????
	wire 		mem_wreg_o;
	wire[4:0] 	mem_wd_o;
	wire[31:0] 	mem_wdata_o;
	
	//????MEM/WB??????????��??��???????	
	wire 		wb_we;
	wire[4:0] 	wb_waddr;
	wire[31:0] 	wb_wdata;
	
	//??????????ID???????��????Regfile???
	wire 		reg1_read, reg2_read;
	wire[31:0] 	reg1_data, reg2_data;
	wire[4:0] 	reg1_addr, reg2_addr;
	
	//???
	wire[5:0] 	stall;
	wire 		stall_from_id, stall_from_ex;	
  
  	//????
	wire 		id_branch_flag_o;
	wire [31:0] branch_address;
	
	wire [31:0] rom_data_icache, ram_data_mem_o;
	wire 		stall_from_icache, stall_from_mem;

	if_state u_if_state(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		.branch_flag_i(id_branch_flag_o),
		.branch_address_i(branch_address),

		.if_pc_o(rom_addr_o),
		.rom_ce_n_o(rom_ce_n_o)
	);

	//直接映像icache，可替换为组相联模块
	icache_direct u_icache(
		.clk(clk),
		.rst(rst),
		.stall_from_icache(stall_from_icache),
		.stall_from_bus(stall_from_bus),

		.rom_addr_i(rom_addr_o),        //??????????
		.rom_ce_n_i(rom_ce_n_o),          //????????????????
		.inst_i(rom_data_i),  
		.inst_o(rom_data_icache)            //??????????
	);

	if_id_reg u_if_id_reg(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		.if_pc_i(rom_addr_o),
		.if_inst_i(rom_data_icache),
		.id_pc_o(id_pc),
		.id_inst_o(id_inst)      	
	);
	
	id_state u_id_state(
		.rst(rst),
		.id_pc_i(id_pc),
		.id_inst_i(id_inst),
        .ex_aluop_i(ex_aluop_o),
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

	   	.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	
		.aluop_o(id_aluop),
		.alusel_o(id_alusel),
		.reg1_o(id_reg1),
		.reg2_o(id_reg2),
		.waddr_o(id_waddr),
		.wreg_o(id_we),
		.inst_o(id_inst_o),
	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_o(branch_address),       
		.link_addr_o(id_link_address_o),

		.stall_from_id(stall_from_id)	
	);

	regfile u_regfile(
		.clk (clk),
		.rst (rst),

		.reg_we_i	   (wb_we),
		.reg_w_addr_i  (wb_waddr),
		.reg_w_data_i  (wb_wdata),
		.reg_re1_i     (reg1_read),
		.reg_r_addr1_i (reg1_addr),
		.reg_re2_i     (reg2_read),
		.reg_r_addr2_i (reg2_addr),

		.reg_r_data1_o (reg1_data),
		.reg_r_data2_o (reg2_data)
	);

	id_ex_reg u_id_ex_reg(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		.id_aluop_i(id_aluop),
		.id_alusel_i(id_alusel),
		.id_reg1_i(id_reg1),
		.id_reg2_i(id_reg2),
		.id_wd_i(id_waddr),
		.id_wreg_i(id_we),
		.id_inst_i(id_inst_o),
		.id_link_address_i(id_link_address_o),

		.ex_aluop_o(ex_aluop_i),
		.ex_alusel_o(ex_alusel_i),
		.ex_reg1_o(ex_reg1_i),
		.ex_reg2_o(ex_reg2_i),
		.ex_wd_o(ex_wd_i),
		.ex_wreg_o(ex_wreg_i),
		.ex_inst_o(ex_inst_i),
		.ex_link_address_o(ex_link_address_i)
	);		
	
	ex_state u_ex_state(
		.clk(clk),
		.rst(rst),
		.stall_from_ex(stall_from_ex),  

		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
	  	.inst_i(ex_inst_i),
		.link_address_i(ex_link_address_i),

		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o)
	);

    ex_mem_reg u_ex_mem_reg(
		.clk(clk),
		.rst(rst),
	  	.stall(stall),

		.ex_wd_i(ex_wd_o),
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
	   	.ex_aluop_i(ex_aluop_o),
		.ex_mem_addr_i(ex_mem_addr_o),
		.ex_reg2_i(ex_reg2_o),

		.mem_wd_o(mem_wd_i),
		.mem_wreg_o(mem_wreg_i),
		.mem_wdata_o(mem_wdata_i),
		.mem_aluop_o(mem_aluop_i),
		.mem_mem_addr_o(mem_mem_addr_i),
		.mem_reg2_o(mem_reg2_i)						       	
	);
	
  	//mem阶段
	mem_state u_mem_state(
		.rst(rst),

		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	    .aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.mem_data_i(ram_data_mem_o),

		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
        .mem_addr_o(ram_addr_o),
		.mem_data_o(ram_data_o),
		.mem_we_n_o(ram_we_n),
		.mem_be_n_o(ram_be_n),
		.mem_ce_n_o(ram_ce_n),
		.mem_oe_n_o(ram_oe_n)	
	);
	
	//此模块是为了方便直接替换为dcache
	mem_controller u_mem(
		.clk(clk),
		.rst(rst),
		.stall_from_mem(stall_from_mem),

		.ram_data_o(ram_data_mem_o),          //?????????

		.mem_addr_i(ram_addr_o),        	  //????��?????
		.mem_data_i(ram_data_o),              //��?????????
		.mem_we_n_i(ram_we_n),          	  //��????????��
		.mem_be_n_i(ram_be_n),         	      //??????????????��
		.mem_oe_n_i(ram_oe_n),          	  //??????????��
		.mem_ce_n_i(ram_ce_n),          	  //?????
		.ram_data_i(ram_data_i)               //��?????????
	);

	//MEM/WB???
	mem_wb_reg u_mem_wb_reg(
		.clk(clk),
		.rst(rst),
        .stall(stall),

		.mem_wd_i(mem_wd_o),
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),

		.wb_wd_o(wb_waddr),
		.wb_wreg_o(wb_we),
		.wb_wdata_o(wb_wdata)											       	
	);
	
	stall_controller u_stall_ctrl(
		.rst(rst),	
		.stall(stall),   

		.stall_from_bus(stall_from_bus),
		.stall_from_id(stall_from_id),
		.stall_from_ex(stall_from_ex),
		.stall_from_mem(stall_from_mem),
		.stall_from_icache(stall_from_icache)
	);

endmodule