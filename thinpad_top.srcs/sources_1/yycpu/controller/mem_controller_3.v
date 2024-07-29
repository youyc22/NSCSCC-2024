//三周期访存

module mem_controller_3(
    input    wire        clk,
    input    wire        rst,
    
    input    wire[31:0]  ram_data_i,
    
    input    wire[31:0]  mem_addr_i,
    input    wire[31:0]  mem_data_i,
    input    wire        mem_we_n_i,
    input    wire        mem_oe_n_i,
    input    wire[3:0]   mem_be_n_i,
    input    wire        mem_ce_n_i,
    
    output   reg[31:0]   ram_data_o,
    output   reg         stall_from_mem
);

    // 状态机定义
    parameter IDLE = 2'b00;    // 空闲状态
    parameter BUSY1 = 2'b01;   // 忙状态1
    parameter BUSY2 = 2'b10;   // 忙状态2
    
    reg[1:0] state, next_state;
    reg[1:0] cycle_count;

    // 处理串口请求
    wire uart = ~mem_ce_n_i & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc));

    // 状态机时序逻辑
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            cycle_count <= 2'b00;
        end else begin
            state <= next_state;
            if (state == BUSY1 || state == BUSY2)
                cycle_count <= cycle_count + 1;
            else
                cycle_count <= 2'b00;
        end
    end

    // 主要的读写操作逻辑
    always@(*) begin
        if(rst) begin
            ram_data_o = 32'b0;
        end else begin
            case(state)
            IDLE:  ram_data_o = (uart || ~mem_oe_n_i) ? ram_data_i : 32'b0;
            BUSY1: ram_data_o = 32'b0;  // 第一个忙周期，不输出数据
            BUSY2: ram_data_o = (~mem_oe_n_i) ? ram_data_i : 32'b0;  // 第二个忙周期，如果是读操作则输出数据
            default: ram_data_o = 32'b0;
            endcase
        end
    end

    // 状态机组合逻辑
    always@(*) begin
        if(rst) begin
            stall_from_mem = 1'b0;
            next_state = IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if((~mem_oe_n_i || ~mem_we_n_i) && ~mem_ce_n_i && !uart) begin
                        next_state = BUSY1;
                        stall_from_mem = 1'b1;
                    end else begin
                        next_state = IDLE;
                        stall_from_mem = 1'b0;
                    end
                end
                BUSY1: begin
                    next_state = BUSY2;
                    stall_from_mem = 1'b1;
                end
                BUSY2: begin
                    if(cycle_count == 2'b10) begin  // 已经经过两个周期
                        next_state = IDLE;
                        stall_from_mem = 1'b0;
                    end else begin
                        next_state = BUSY2;
                    end
                end
                default: next_state = IDLE;
            endcase
        end
    end
endmodule