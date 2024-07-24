module dcache(
    // ʱ�Ӻ͸�λ�ź�
    input    wire        clk,
    input    wire        rst,

    // �� SRAM ���ӵĽӿ�
    input    wire[31:0]  ram_data_i,        // �� SRAM ��ȡ������

    // �� MEM �׶����ӵĽӿ�
    input    wire[31:0]  mem_addr_i,        // ��/д��ַ
    input    wire[31:0]  mem_data_i,        // Ҫд�������
    input    wire        mem_we_n_i,        // дʹ�ܣ�����Ч
    input    wire        mem_oe_n_i,        // ��ʹ�ܣ�����Ч
    input    wire[3:0]   mem_be_n_i,        // �ֽ�ѡ���ź�
    input    wire        mem_ce_n_i,        // Ƭѡ�ź�
    output   reg[31:0]   ram_data_o,        // ��ȡ���������
    output   reg         stall              // ��ˮ����ͣ�ź�
);

    // �����������
    parameter Cache_Num = 32;       // ��������
    parameter Tag = 16;             // ��ǩλ��
    parameter Cache_Index = 5;      // ��������λ��
    parameter Block_Offset = 2;     // ����ƫ��λ��

    // ����洢�ṹ
    reg[31:0] cache_mem[0:Cache_Num-1];     // �������ݴ洢
    reg[Tag-1:0] cache_tag[0:Cache_Num-1];  // �����ǩ�洢
    reg[3:0]     cache_valid[Cache_Num-1:0];// ������Чλ�洢

    // ״̬������
    parameter IDLE = 0;         // ����״̬
    parameter READ_SRAM = 1;    // �� SRAM ״̬
    parameter WRITE_SRAM = 2;   // д SRAM ״̬

    reg[1:0] state, next_state;

    // ״̬��ʱ���߼�
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // ����������
    wire uart_req = (~mem_ce_n_i & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc)))?1'b1:1'b0;

    // �����ַ����
    wire [Tag-1:0] ram_tag_i = mem_addr_i[22:7];           // �ӵ�ַ����ȡ��ǩ
    wire [Cache_Index-1:0]  ram_cache_i = mem_addr_i[6:2]; // �ӵ�ַ����ȡ��������

    wire hit = 1'b0; 
    
    reg finish_read;  // ����ɱ�־
    reg finish_write; // д��ɱ�־

    integer i;
    reg[63:0] wb_data_r;

    // ��Ҫ�Ļ�������߼�
    always@(*) begin
        if(rst) begin
            // ��λʱ��ʼ������
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
                // ����״̬�������д����
                finish_read = 1'b0;
                finish_write = 1'b0;
                if(hit && !uart_req) begin
                    // ���������ҷǴ�������ʱ��ֱ�Ӵӻ����ȡ����
                    ram_data_o = cache_mem[ram_cache_i];
                end else if(uart_req) begin
                    // ��������ʱ��ֱ�Ӵ� SRAM ��ȡ����
                    ram_data_o = ram_data_i;                
                end else begin
                    ram_data_o = 32'b0;
                end
            end
            READ_SRAM: begin      
                // �� SRAM ��ȡ���ݲ����»���
                ram_data_o = ram_data_i;
                finish_read = 1'b1;         
                cache_mem[ram_cache_i] = ram_data_i;
                cache_valid[ram_cache_i] = ~mem_be_n_i;
                cache_tag[ram_cache_i] = ram_tag_i;
            end
            WRITE_SRAM: begin    
                // д�� SRAM �����»���
                ram_data_o = 32'b0;           
                finish_write = 1'b1;   
                // �����ֽ�ѡ���źŸ��»���
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

    // ״̬������߼�
    always@(*) begin
        if(rst) begin
            stall = 1'b0;
            next_state = IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if(~mem_oe_n_i && (hit != 1'b1) && ~mem_ce_n_i && !uart_req) begin
                        // ������δ���У������ SRAM ״̬
                        next_state = READ_SRAM;
                        stall = 1'b1;
                    end else if(~mem_we_n_i && ~mem_ce_n_i && !uart_req) begin
                        // д���󣬽���д SRAM ״̬
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