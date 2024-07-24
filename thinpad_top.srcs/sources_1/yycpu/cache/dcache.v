module dcache(
    // 时钟和复位信号
    input    wire        clk,
    input    wire        rst,

    // 与 SRAM 连接的接口
    input    wire[31:0]  ram_data_i,        // 从 SRAM 读取的数据

    // 与 MEM 阶段连接的接口
    input    wire[31:0]  mem_addr_i,        // 读/写地址
    input    wire[31:0]  mem_data_i,        // 要写入的数据
    input    wire        mem_we_n_i,        // 写使能，低有效
    input    wire        mem_oe_n_i,        // 读使能，低有效
    input    wire[3:0]   mem_be_n_i,        // 字节选择信号
    input    wire        mem_ce_n_i,        // 片选信号
    output   reg[31:0]   ram_data_o,        // 读取的数据输出
    output   reg         stall              // 流水线暂停信号
);

    // 缓存参数定义
    parameter Cache_Num = 32;       // 缓存行数
    parameter Tag = 16;             // 标签位数
    parameter Cache_Index = 5;      // 缓存索引位数
    parameter Block_Offset = 2;     // 块内偏移位数

    // 缓存存储结构
    reg[31:0] cache_mem[0:Cache_Num-1];     // 缓存数据存储
    reg[Tag-1:0] cache_tag[0:Cache_Num-1];  // 缓存标签存储
    reg[3:0]     cache_valid[Cache_Num-1:0];// 缓存有效位存储

    // 状态机定义
    parameter IDLE = 0;         // 空闲状态
    parameter READ_SRAM = 1;    // 读 SRAM 状态
    parameter WRITE_SRAM = 2;   // 写 SRAM 状态

    reg[1:0] state, next_state;

    // 状态机时序逻辑
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 处理串口请求
    wire uart_req = (~mem_ce_n_i & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc)))?1'b1:1'b0;

    // 缓存地址解析
    wire [Tag-1:0] ram_tag_i = mem_addr_i[22:7];           // 从地址中提取标签
    wire [Cache_Index-1:0]  ram_cache_i = mem_addr_i[6:2]; // 从地址中提取缓存索引

    wire hit = 1'b0; 
    
    reg finish_read;  // 读完成标志
    reg finish_write; // 写完成标志

    integer i;
    reg[63:0] wb_data_r;

    // 主要的缓存操作逻辑
    always@(*) begin
        if(rst) begin
            // 复位时初始化缓存
            for(i=0 ; i < 32 ; i=i+1) begin
                cache_mem[i] = 32'b0;
                cache_tag[i] = 16'b0;
                cache_valid[i] = 4'b0;
            end  
            finish_read = 1'b0;
            finish_write = 1'b0;
            ram_data_o = 32'b0;
        end else begin
            case(state)
            IDLE: begin
                // 空闲状态：处理读写请求
                finish_read = 1'b0;
                finish_write = 1'b0;
                if(hit && !uart_req) begin
                    // 缓存命中且非串口请求时，直接从缓存读取数据
                    ram_data_o = cache_mem[ram_cache_i];
                end else if(uart_req) begin
                    // 串口请求时，直接从 SRAM 读取数据
                    ram_data_o = ram_data_i;                
                end else begin
                    ram_data_o = 32'b0;
                end
            end
            READ_SRAM: begin      
                // 从 SRAM 读取数据并更新缓存
                ram_data_o = ram_data_i;
                finish_read = 1'b1;         
                cache_mem[ram_cache_i] = ram_data_i;
                cache_valid[ram_cache_i] = ~mem_be_n_i;
                cache_tag[ram_cache_i] = ram_tag_i;
            end
            WRITE_SRAM: begin    
                // 写入 SRAM 并更新缓存
                ram_data_o = 32'b0;           
                finish_write = 1'b1;   
                // 根据字节选择信号更新缓存
                if(cache_valid[ram_cache_i] != ~mem_be_n_i && cache_valid[ram_cache_i] != 4'b0) begin
                    case(mem_be_n_i)
                        4'b0000: begin 
                            cache_mem[ram_cache_i] =  mem_data_i;
                            cache_valid[ram_cache_i] = 4'b1111;
                        end
                        4'b1110: begin
                            cache_mem[ram_cache_i][7:0] = mem_data_i[7:0];
                            cache_valid[ram_cache_i][0] = 1'b1;
                        end
                        4'b1101: begin
                            cache_mem[ram_cache_i][15:8] = mem_data_i[15:8];
                            cache_valid[ram_cache_i][1] = 1'b1;
                        end
                        4'b1011: begin
                            cache_mem[ram_cache_i][23:16] = mem_data_i[23:16];
                            cache_valid[ram_cache_i][2] = 1'b1;
                        end
                        4'b0111: begin
                            cache_mem[ram_cache_i][31:24] = mem_data_i[31:24];
                            cache_valid[ram_cache_i][3] = 1'b1;
                        end
                        default: begin
                            cache_mem[ram_cache_i] = mem_data_i;
                            cache_valid[ram_cache_i][0] = 4'b0000;
                        end
                    endcase
                end else begin
                    cache_mem[ram_cache_i] = mem_data_i;
                    cache_valid[ram_cache_i] = ~mem_be_n_i;
                end
                cache_tag[ram_cache_i] = ram_tag_i;
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
                    if(~mem_oe_n_i && (hit != 1'b1) && ~mem_ce_n_i && !uart_req) begin
                        // 读缓存未命中，进入读 SRAM 状态
                        next_state = READ_SRAM;
                        stall = 1'b1;
                    end else if(~mem_we_n_i && ~mem_ce_n_i && !uart_req) begin
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
endmodule