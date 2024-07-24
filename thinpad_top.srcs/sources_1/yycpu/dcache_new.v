module dcache_new(
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

    reg finish_read;  // 读完成标志
    reg finish_write; // 写完成标志

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
                if(uart_req || !mem_oe_n_i) begin
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
                    if(~mem_oe_n_i && ~mem_ce_n_i && !uart_req) begin
                        // 读请求，进入读 SRAM 状态
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