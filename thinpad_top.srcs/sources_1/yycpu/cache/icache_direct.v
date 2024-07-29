module icache_direct(
    // 时钟和复位信号
    input wire                                  clk,
    input wire                                  rst,

    // CPU 接口
    (* DONT_TOUCH = "1" *) input    wire[31:0]  pc_i,              // CPU 请求的指令地址
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_n_i,        // 指令存储器片选信号，低电平有效
    output   reg [31:0]                         inst_o,            // 输出的指令
    output   reg                                stall_from_icache, // 缓存暂停信号
    
    // SRAM 接口
    input wire                                  stall_from_bus,    // 总线暂停信号
    input wire [31:0]                           inst_i             // 从 SRAM 读取的指令

);
    // 缓存参数定义
    parameter cache_lines = 32;        // 缓存行数            
    parameter cache_index = $clog2(cache_lines);      // 标记位宽
    parameter tag_num = 20-cache_index;   // 索引位宽
    
    // 状态机状态定义
    parameter IDLE = 0;              // 空闲状态
    parameter BUSY = 1;              // 读取 SRAM 状态

    // 缓存存储单元
    reg[31:0]            cache_data[0:cache_lines-1];   // 缓存数据存储
    reg[tag_num-1:0]     cache_tag[0:cache_lines-1];   // 缓存标记存储
    reg[cache_lines-1:0]  cache_valid;                // 缓存有效位

    // 状态机状态寄存器
    reg state, next_state, finish;

    integer i;  // 用于初始化的循环变量

    // 地址解析和命中判断
    wire [tag_num-1:0]      ram_tag_i = pc_i[21:22-tag_num];             // 从地址中提取标记
    wire [cache_index-1:0]  ram_cache_i = pc_i[6:7-cache_index];            // 从地址中提取索引
    wire hit = (state==IDLE) && cache_valid[ram_cache_i] && (cache_tag[ram_cache_i]==ram_tag_i);  // 命中条件：空闲状态 + 有效 + 标记匹配
    
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
            finish = 1'b0;
            inst_o = `ZeroWord;             // 复位时输出全0
        end else begin
            case(state)
            IDLE: begin
                finish = 1'b0;       
                if(hit && ~stall_from_bus) begin
                    inst_o = cache_data[ram_cache_i];  // 命中时直接从缓存输出
                end else begin
                    inst_o = `ZeroWord;     // 未命中时输出全0
                end
            end
            BUSY: begin       
                inst_o = inst_i;            // 从 SRAM 读取的指令直接输出
                finish = 1'b1;              // 标记读取完成
            end
            default: begin 
                finish = 1'b0;
                inst_o = 32'hzzzzzzzz;      // 默认输出高阻态
            end
            endcase
        end
    end

    // 缓存更新逻辑
    always@(posedge clk or posedge rst) begin
        if(rst) begin      // 复位时初始化缓存
            for(i=0; i < cache_lines; i=i+1) begin
                cache_data[i] <= 32'b0;
                cache_tag[i] <= {tag_num{1'b0}};
            end  
            cache_valid <= {cache_lines{1'b0}};
        end else begin
            case(state)
            BUSY: begin       
                cache_data[ram_cache_i] <= inst_i;        // 更新缓存数据
                cache_valid[ram_cache_i] <= 1'b1;        // 设置有效位
                cache_tag[ram_cache_i] <= ram_tag_i;     // 更新标记
            end
            default: begin    // 保持缓存状态不变
                cache_data[ram_cache_i] <= cache_data[ram_cache_i];
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
            next_state = BUSY;
        end else begin
            case(state)
                IDLE: begin
                    if(~rom_ce_n_i && ~hit && ~stall_from_bus) begin  // 需要读取且未命中且总线未暂停
                        next_state = BUSY;
                        stall_from_icache = 1'b1;  // 发出暂停信号
                    end else begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;
                    end
                end
                BUSY: begin
                    if(finish) begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;  // 读取完成，解除暂停
                    end else begin
                        next_state = BUSY;
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