module sram_controller (
    input wire          clk,
    input wire          rst,

    input wire [31:0]   inst_addr_i,
    input wire          rom_ce_n_i,
    output reg [31:0]   inst_o,

    input wire [31:0]   mem_data_i,
    input wire [31:0]   mem_addr_i,
    input wire [3:0]    mem_be_n,
    input wire          mem_ce_n,
    input wire          mem_oe_n,
    input wire          mem_we_n,
    output reg [31:0]   ram_data_o,

    inout wire [31:0]   base_ram_data,
    output reg [19:0]   base_ram_addr,
    output reg [3:0]    base_ram_be_n,
    output reg          base_ram_ce_n,
    output reg          base_ram_oe_n,
    output reg          base_ram_we_n,

    inout wire [31:0]   ext_ram_data,
    output reg [19:0]   ext_ram_addr,
    output reg [3:0]    ext_ram_be_n,
    output reg          ext_ram_ce_n,
    output reg          ext_ram_oe_n,
    output reg          ext_ram_we_n,

    output reg          stall_inst,
    input wire [31:0]   serial_i
);

    parameter BASE_RAM_START = 32'h80000000;
    parameter EXT_RAM_START  = 32'h80400000;
    
    wire [31:0] base_ram_o, ext_ram_o;
    wire is_base_ram = (mem_addr_i[31:22] == BASE_RAM_START[31:22]);
    wire is_ext_ram  = (mem_addr_i[31:22] == EXT_RAM_START[31:22]);
    wire is_SerialState = (mem_addr_i == 32'hBFD003FC); //串口状态地址
    wire is_SerialData  = (mem_addr_i == 32'hBFD003F8); //串口数据地址

    assign base_ram_data = (is_base_ram && ~mem_we_n) ? mem_data_i : 32'hzzzzzzzz;
    assign base_ram_o = base_ram_data;      

    assign ext_ram_data = (is_ext_ram && ~mem_we_n) ? mem_data_i : 32'hzzzzzzzz;
    assign ext_ram_o = ext_ram_data;

    always @(*) begin
        {base_ram_addr, base_ram_be_n, base_ram_ce_n, base_ram_oe_n, base_ram_we_n} = 
        {20'h00000,     4'b1111,       1'b0,          1'b1,          1'b1};
        stall_inst = 1'b0;
        inst_o = 32'h0;
        if(is_base_ram) begin      
            {base_ram_addr, base_ram_be_n, base_ram_ce_n, base_ram_oe_n, base_ram_we_n} =
            {mem_addr_i[21:2], mem_be_n,   1'b0,          mem_oe_n,      mem_we_n};    
            stall_inst = 1'b1;//涉及baseram数据操作时暂停流水线
            inst_o = 32'h0;
        end else begin        //不涉及时继续取指令
            {base_ram_addr, base_ram_be_n, base_ram_ce_n, base_ram_oe_n, base_ram_we_n} =
            {inst_addr_i[21:2], 4'b0000,   1'b0,          1'b0,          1'b1};            
            if(is_SerialData)begin              
                stall_inst = 1'b1;
                inst_o = 32'd0;
            end else begin
                stall_inst = 1'b0;
                inst_o = base_ram_o;
            end
        end
    end

    always @(*) begin
        {ext_ram_addr, ext_ram_be_n, ext_ram_ce_n, ext_ram_oe_n, ext_ram_we_n} = 
        {20'h00000,    4'b1111,      1'b0,         1'b1,         1'b1};
        if(is_ext_ram) begin  
            {ext_ram_addr, ext_ram_be_n, ext_ram_ce_n, ext_ram_oe_n, ext_ram_we_n} = 
            {mem_addr_i[21:2], mem_be_n, 1'b0,         mem_oe_n,     mem_we_n};
        end else begin
        end
    end

    always @(*) begin
        if (is_SerialState || is_SerialData) begin
            ram_data_o = serial_i; 
        end else if (is_base_ram) begin
            ram_data_o = base_ram_o;       
        end else if (is_ext_ram) begin
            ram_data_o = ext_ram_o;     
        end else begin
            ram_data_o = 32'd0;     
        end
    end
    
endmodule
