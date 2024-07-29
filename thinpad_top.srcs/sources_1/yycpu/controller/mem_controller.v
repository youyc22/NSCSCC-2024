//两周期访�?

module mem_controller(
    // 时钟和复位信�?
    input    wire        clk,
    input    wire        rst,
    output   reg         stall_from_mem,    // 流水线暂停信�?

    // �? SRAM 连接的接�?
    input    wire[31:0]  ram_data_i,        // �? SRAM 读取的数�?

    // �? MEM 阶段连接的接�?
    input    wire[31:0]  mem_addr_i,        // �?/写地�?
    input    wire[31:0]  mem_data_i,        // 要写入的数据
    input    wire        mem_we_n_i,        // 写使能，低有�?
    input    wire        mem_oe_n_i,        // 读使能，低有�?
    input    wire[3:0]   mem_be_n_i,        // 字节选择信号
    input    wire        mem_ce_n_i,        // 片�?�信�?
    output   reg[31:0]   ram_data_o         // 读取的数据输�?
);

    // 状�?�机定义
    parameter IDLE = 0;         // 空闲状�??
    parameter BUSY = 1;         // 忙状�?
    reg state, next_state, finish;

    // 处理串口请求
    wire uart = ~mem_ce_n_i & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc));

    // 状�?�机时序逻辑
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 主要的读写操作�?�辑
    always@(*) begin
        if(rst) begin
            finish = 1'b0;
            ram_data_o = 32'b0;
        end else begin
            case(state)
            IDLE:       begin
                finish = 1'b0;
                ram_data_o = (uart || ~mem_oe_n_i) ? ram_data_i : 32'b0;
            end
            BUSY:       begin
                finish = 1'b1;
                ram_data_o = (~mem_oe_n_i) ? ram_data_i : 32'b0;
            end
            default:    begin 
            end
            endcase
        end
    end

    // 状�?�机组合逻辑
    always@(*) begin
        if(rst) begin
            stall_from_mem = 1'b0;
            next_state = IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if((~mem_oe_n_i || ~mem_we_n_i) && ~mem_ce_n_i && !uart) begin
                        // 读请求，进入�? SRAM 状�??
                        next_state = BUSY;
                        stall_from_mem = 1'b1;
                    end else begin
                        next_state = IDLE;
                        stall_from_mem = 1'b0;
                    end
                end
                BUSY: begin
                    if(finish) begin
                        next_state = IDLE;
                        stall_from_mem = 1'b0;
                    end else begin
                        next_state = BUSY;  
                    end 
                end
                default: next_state = IDLE;
            endcase
        end
    end
endmodule