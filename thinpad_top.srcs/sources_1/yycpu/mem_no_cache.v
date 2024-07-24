module mem_no(
	input wire						clk,
	input wire						rst,
	
    // 与 SRAM 连接的接口
    input wire[31:0]  				ram_data_i,   

	//锟斤拷锟斤拷执锟叫阶段碉拷锟斤拷息	
	input wire[4:0]       			wd_i,
	input wire                    	wreg_i,
	input wire[31:0]				wdata_i,

	//锟矫达拷
	input wire[4:0]        			aluop_i,
	input wire[31:0]          		mem_addr_i,
	input wire[31:0]          		reg2_i,
	//input wire[31:0]          		mem_data_i,
	
	//锟酵碉拷锟斤拷写锟阶段碉拷锟斤拷息
	output reg[4:0]      			wd_o,
	output reg                   	wreg_o,
	output reg[31:0]			 	wdata_o,
	
	//锟矫达拷
	output reg[31:0]          		mem_addr_o,
	output reg[31:0]          		mem_data_o,
	output reg					 	mem_we_n,		//写使锟杰ｏ拷锟斤拷位锟斤拷效
	output reg[3:0]              	mem_be_n,		//锟街斤拷选锟今，碉拷位锟斤拷效
	output reg                   	mem_ce_n,		//锟斤拷位锟斤拷效
	output reg                  	mem_oe_n, 		//锟斤拷使锟杰ｏ拷锟斤拷位锟斤拷效

	output reg                      stall
);
	wire [31:0]                     mem_data_i;
	reg [31:0]                      ram_data_o;
	// 状态机定义
    parameter IDLE = 0;         // 空闲状态
    parameter READ_SRAM = 1;    // 读 SRAM 状态
    parameter WRITE_SRAM = 2;   // 写 SRAM 状态

    reg[1:0] state, next_state;
	// 处理串口请求
    wire uart_req = (~mem_ce_n & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc)))?1'b1:1'b0;

    reg finish_read;  // 读完成标志
    reg finish_write; // 写完成标志

	// 状态机时序逻辑
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

	assign mem_data_i = ram_data_o;

	// 主要的读写操作逻辑
    always@(*) begin
        if(rst) begin
            finish_read = 1'b0;
            finish_write = 1'b0;
            ram_data_o = 32'b0;
        end else begin
            case(state)
            IDLE: begin
                finish_read = 1'b0;
                finish_write = 1'b0;
                if(uart_req || !mem_oe_n) begin
                    // 串口请求或读请求时，直接从 SRAM 读取数据
                    ram_data_o = ram_data_i;                
                end else begin
                    ram_data_o = 32'b0;
                end
            end
            READ_SRAM: begin      
                // 从 SRAM 读取数据
                ram_data_o = ram_data_i;
                finish_read = 1'b1;         
            end
            WRITE_SRAM: begin    
                // 写入 SRAM
                ram_data_o = 32'b0;           
                finish_write = 1'b1;   
            end
            default: begin end
            endcase
        end
    end

    // 状态机组合逻辑
    always@(*) begin
        if(rst) begin
            stall = 1'b0;
            next_state = IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if(~mem_oe_n && ~mem_ce_n && !uart_req) begin
                        // 读请求，进入读 SRAM 状态
                        next_state = READ_SRAM;
                        stall = 1'b1;
                    end else if(~mem_we_n && ~mem_ce_n && !uart_req) begin
                        // 写请求，进入写 SRAM 状态
                        next_state = WRITE_SRAM;
                        stall = 1'b1;
                    end else begin
                        next_state = IDLE;
                        stall = 1'b0;
                    end
                end
                READ_SRAM: begin
                    if(finish_read) begin
                        next_state = IDLE;
                        stall = 1'b0;
                    end else begin
                        next_state = READ_SRAM;  
                    end 
                end
                WRITE_SRAM: begin
                    if(finish_write) begin
                        next_state = IDLE;
                        stall = 1'b0;
                    end else begin
                        next_state = WRITE_SRAM;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end

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