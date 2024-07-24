`include "defines.v"

module icache_direct_1(
    input wire                    clk,
    input wire                    rst,
    (* DONT_TOUCH = "1" *) input  wire[31:0]  rom_addr_i,
    (* DONT_TOUCH = "1" *) input  wire        rom_ce_n_i,
    output reg [31:0]             inst_o,
    output reg                    stall,
    input wire                    stall_from_bus,
    input wire [31:0]             inst_i
);

parameter Cache_Num = 32;
parameter Tag = 15;
parameter Cache_Index = 5;
parameter Block_Offset = 2;

reg[Tag-1:0] cache_tag[0:Cache_Num-1];
reg[Cache_Num-1:0] cache_valid;

parameter IDLE=0;
parameter READ_SRAM=1;
reg[1:0]  state, next_state;

wire [Tag-1:0] ram_tag_i = rom_addr_i[31:17];
wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[16:12];

wire hit = (state==IDLE) ? cache_valid[ram_cache_i] && (cache_tag[ram_cache_i]==ram_tag_i) : 1'b0;

reg finish_read;
integer i;

// 双端口BRAM for cache_mem
wire [31:0] cache_mem_doutb;
reg cache_mem_wea;
reg [Cache_Index-1:0] cache_mem_addra, cache_mem_addrb;

blk_mem_gen_0 icache_memory (
    .clka(clk),
    .ena(1'b1),
    .wea(cache_mem_wea),
    .addra(cache_mem_addra),
    .dina(inst_i),
    .clkb(clk),
    .enb(1'b1),
    .addrb(cache_mem_addrb),
    .doutb(cache_mem_doutb)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    if(rst) begin
        finish_read = 1'b0;
        inst_o = `ZeroWord;
    end else begin
        case(state)
        IDLE: begin
            finish_read = 1'b0;       
            if(hit && ~stall_from_bus) begin
                cache_mem_addrb = ram_cache_i;
                inst_o = cache_mem_doutb;
            end else begin
                inst_o = `ZeroWord;
            end
        end
        READ_SRAM: begin       
            inst_o = inst_i;
            finish_read = 1'b1;   
        end
        default: begin 
            finish_read = 1'b0;
            inst_o = 32'hzzzzzzzz;
        end
        endcase
    end
end

wire rst_n = ~rst;
always @(posedge clk or posedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i < Cache_Num; i=i+1) begin
            cache_tag[i] <= 15'b0;
        end  
        cache_valid <= 32'h00000000;
        cache_mem_wea <= 1'b0;
        cache_mem_addra <= 5'b0;
    end else begin
        case(state)
        READ_SRAM: begin       
            cache_mem_wea <= 1'b1;
            cache_mem_addra <= ram_cache_i;
            cache_valid[ram_cache_i] <= 1'b1;
            cache_tag[ram_cache_i] <= ram_tag_i;
        end
        default: begin 
            cache_mem_wea <= 1'b0;
            cache_mem_addra <= cache_mem_addra;
            cache_valid[ram_cache_i] <= cache_valid[ram_cache_i];
            cache_tag[ram_cache_i] <= cache_tag[ram_cache_i];
        end
        endcase
    end
end

always @(*) begin
    if(rst) begin
        stall = 1'b0;     
        next_state = READ_SRAM;
    end else begin
        case(state)
            IDLE: begin
                if(~rom_ce_n_i && ~hit && ~stall_from_bus) begin
                    next_state = READ_SRAM;
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
                end
                else begin
                    next_state = READ_SRAM;
                    stall = 1'b1;  
                end 
            end
            default: begin 
                next_state = IDLE;
                stall = 1'b0;
            end
        endcase
    end
end

endmodule