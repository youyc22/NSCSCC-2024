
module icache_direct(
    //???
    input wire                                  clk,
    input wire                                  rst,

    //??cpu????
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        //?????????
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_n_i,          //???��????????
    output   reg [31:0]                         inst_o,            //??????????
    output   reg                                stall_from_icache,
    //??sram??????????
    input wire                                  stall_from_bus,
    input wire [31:0]                           inst_i          //??????????

);

    parameter Cache_Num = 32;
    parameter Tag = 15;
    parameter Cache_Index = 5;
    parameter Block_Offset = 2;
    parameter IDLE=0;
    parameter READ_SRAM=1;

    reg[31:0] cache_mem[0:Cache_Num-1];//cache memory
    reg[Tag-1:0] cache_tag[0:Cache_Num-1];//cache tag
    reg[Cache_Num-1:0]        cache_valid;//cache valid
    reg[1:0]  state, next_state;
    reg finish_read;

    integer i;

    //hit(����ָ�����У�д����û������)
    wire [Tag-1:0] ram_tag_i = rom_addr_i[21:7];//ram tag
    wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[6:2];//ram cache block addr
    wire hit = (state==IDLE)?cache_valid[ram_cache_i]&&(cache_tag[ram_cache_i]==ram_tag_i):1'b0;//tag?????valid=1???��?��??��??
    wire rst_n = ~rst;
    
    always@(posedge clk or posedge rst)begin
        if(rst)begin
            state<=IDLE;
        end else begin
            state<=next_state;
        end
    end

    //??????
    always@(*)  begin
        if(rst)begin
            finish_read = 1'b0;
            inst_o = `ZeroWord;       //????????
        end else begin
            case(state)
            IDLE:       begin
                finish_read = 1'b0;       
                if(hit && ~stall_from_bus)begin
                    inst_o = cache_mem[ram_cache_i];
                end else begin
                    inst_o = `ZeroWord;
                end
            end
            READ_SRAM: begin       
                inst_o = inst_i;       //????????  
                finish_read = 1'b1;   
            end
            default:   begin 
                finish_read = 1'b0;
                inst_o = 32'hzzzzzzzz;
            end
            endcase
        end
    end

    always@(posedge clk or posedge rst_n)   begin
        if(!rst_n)begin
            for(i=0; i < 32; i=i+1)   begin
                cache_mem[i] <= 32'b0;
                cache_tag[i] <= 15'b0;
            end  
            cache_valid <= 32'h00000000;
        end else begin
            case(state)
            READ_SRAM:  begin       
                cache_mem[ram_cache_i] <= inst_i;
                cache_valid[ram_cache_i] <= 1'b1;
                cache_tag[ram_cache_i] <= ram_tag_i;//cache tag  
            end
            default:    begin 
                cache_mem[ram_cache_i] <= cache_mem[ram_cache_i];
                cache_valid[ram_cache_i] <= cache_valid[ram_cache_i];
                cache_tag[ram_cache_i] <= cache_tag[ram_cache_i];//cache tag  
            end
            endcase
        end
        end

    //??????
    always@(*)begin
        if(rst)begin
            stall_from_icache = 1'b0;     
            next_state = READ_SRAM;
        end else begin
            case(state)
                IDLE:begin
                    if(~rom_ce_n_i && ~hit && ~stall_from_bus)begin//????��????
                        next_state = READ_SRAM;
                        stall_from_icache = 1'b1;
                    end else begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;
                    end
                end
                READ_SRAM:begin
                    if(finish_read)begin
                        next_state = IDLE;
                        stall_from_icache = 1'b0;
                        end
                    else begin
                        next_state = READ_SRAM;
                        stall_from_icache = 1'b1;  
                    end 
                end
                default:begin 
                    next_state = IDLE;
                    stall_from_icache = 1'b0;
                end
            endcase
        end
    end

endmodule