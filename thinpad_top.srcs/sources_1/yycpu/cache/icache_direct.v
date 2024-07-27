module icache_direct(
    // 时钟和复位信号
    input wire                                  clk,
    input wire                                  rst,

    // CPU 接口
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        // CPU 请求的指令地址
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_n_i,        // 指令存储器片选信号，低电平有效
    output   reg [31:0]                         inst_o,            // 输出的指令
    output   reg                                stall_from_icache, // 缓存暂停信号
    
    // SRAM 接口
    input wire                                  stall_from_bus,    // 总线暂停信号
    input wire [31:0]                           inst_i             // 从 SRAM 读取的指令

);

    // 缓存参数定义
    parameter Cache_Num = 32;        // 缓存行数
    parameter Tag = 15;              // 标记位宽
    parameter Cache_Index = 5;       // 索引位宽
    parameter Block_Offset = 2;      // 块内偏移位宽（未使用）
    
    // 状态机状态定义
    parameter IDLE = 0;              // 空闲状态
    parameter READ_SRAM = 1;         // 读取 SRAM 状态

    // 缓存存储单元
    reg[31:0] cache_mem[0:Cache_Num-1];     // 缓存数据存储
    reg[Tag-1:0] cache_tag[0:Cache_Num-1];  // 缓存标记存储
    reg[Cache_Num-1:0] cache_valid;         // 缓存有效位
    
    // 状态机相关寄存器
    reg[1:0]  state, next_state;
    reg finish_read;                        // 读取完成标志

    integer i;  // 用于初始化的循环变量

    // 地址解析和命中判断
    wire [Tag-1:0] ram_tag_i = rom_addr_i[21:7];           // 从地址中提取标记
    wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[6:2];  // 从地址中提取索引
    wire hit = (state==IDLE) ? cache_valid[ram_cache_i] && (cache_tag[ram_cache_i]==ram_tag_i) : 1'b0;  // 命中条件：空闲状态 + 有效 + 标记匹配
    wire rst_n = ~rst;  // 复位信号取反
    
    // 状态机时序逻辑
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 指令输出和读取完成标志逻辑
    always@(*) begin
        if(rst) begin
            finish_read = 1'b0;
            inst_o = `ZeroWord;       // 复位时输出全0
        end else begin
            case(state)
            IDLE: begin
                finish_read = 1'b0;       
                if(hit && ~stall_from_bus) begin
                    inst_o = cache_mem[ram_cache_i];  // 命中时直接从缓存输出
                end else begin
                    inst_o = `ZeroWord;  // 未命中时输出全0
                end
            end
            READ_SRAM: begin       
                inst_o = inst_i;       // 从 SRAM 读取的指令直接输出
                finish_read = 1'b1;    // 标记读取完成
            end
            default: begin 
                finish_read = 1'b0;
                inst_o = 32'hzzzzzzzz;  // 默认输出高阻态
            end
            endcase
        end
    end

    // 缓存更新逻辑
    always@(posedge clk or posedge rst_n) begin
        if(!rst_n) begin
            // 复位时初始化缓存
            for(i=0; i < 32; i=i+1) begin
                cache_mem[i] <= 32'b0;
                cache_tag[i] <= 15'b0;
            end  
            cache_valid <= 32'h00000000;
        end else begin
            case(state)
            READ_SRAM: begin       
                cache_mem[ram_cache_i] <= inst_i;        // 更新缓存数据
                cache_valid[ram_cache_i] <= 1'b1;        // 设置有效位
                cache_tag[ram_cache_i] <= ram_tag_i;     // 更新标记
            end
            default: begin 
                // 保持缓存状态不变
                cache_mem[ram_cache_i] <= cache_mem[ram_cache_i];
                cache_valid[ram_cache_i] <= cache_valid[ram_cache_i];
                cache_tag[ram_cache_i] <= cache_tag[ram_cache_i];
            end
            endcase
        end
    end

    // 状态机组合逻辑
    always@(*) begin
        if(rst) begin
            stall_from_icache = 1'b0;     
            next_state = READ_SRAM;
        end else begin
            case(state)
                IDLE: begin
                    if(~rom_ce_n_i && ~hit && ~stall_from_bus) begin  // 需要读取且未命中且总线未暂停
                        next_state = READ_SRAM;
                        stall_from_icache = 1'b1;  // 发出暂停信号
                    end else begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;
                    end
                end
                READ_SRAM: begin
                    if(finish_read) begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;  // 读取完成，解除暂停
                    end else begin
                        next_state = READ_SRAM;
                        stall_from_icache = 1'b1;  // 继续暂停
                    end 
                end
                default: begin 
                    next_state = IDLE;
                    stall_from_icache = 1'b0;
                end
            endcase
        end
    end

endmodule