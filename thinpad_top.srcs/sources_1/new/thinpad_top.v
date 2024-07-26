`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED������?1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С����?���?1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С����?���?1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���?0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���?0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�??
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����??
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk1;
reg reset1;

pll_example clock_gen 
 (
  .clk_in1(clk_50M),
  .clk_out1(clk1),
  .reset(reset_btn),
  .locked(locked)
 );

always @(posedge clk1 or negedge locked) begin
    if (~locked) reset1 <= 1;
    else         reset1 <= 0;
end

wire [31:0]  rom_addr_o;
wire         rom_ce_n;
wire [31:0]  inst_i;
wire [31:0]  serial_i;
wire [31:0]  ram_data_i;
wire [31:0]  ram_addr_o;
wire [31:0]  ram_data_o;
wire         ram_we_n;
wire         ram_oe_n;
wire         ram_ce_n;
wire [3:0]   ram_be_n;
wire         stall_from_bus;


yycpu u_yycpu(
    .clk            (clk1),
    .rst            (reset1),

    .rom_addr_o     (rom_addr_o),
    .rom_ce_n_o     (rom_ce_n),
    .rom_data_i     (inst_i),
    .stall_from_bus (stall_from_bus),

    .ram_data_i     (ram_data_i),
    .ram_addr_o     (ram_addr_o),
    .ram_data_o     (ram_data_o),
    .ram_we_n       (ram_we_n),
    .ram_be_n       (ram_be_n),
    .ram_ce_n       (ram_ce_n),
    .ram_oe_n       (ram_oe_n)
);

uart_controller u_uart(
    .clk            (clk1),
    .rst            (reset1),
    .txd            (txd),
    .rxd            (rxd),
    .mem_data_i     (ram_data_o),
    .mem_addr_i     (ram_addr_o),
    .mem_oe_n       (ram_oe_n),
    .mem_we_n       (ram_we_n),
    .serial_o       (serial_i)
);

sram_controller u_sram(
	.clk                (clk1),  
	.rst                (reset1),

	.inst_addr_i        (rom_addr_o),
	.rom_ce_n_i         (rom_ce_n),
	.inst_o             (inst_i),

	.ram_data_o         (ram_data_i),
	.mem_addr_i         (ram_addr_o),
	.mem_data_i         (ram_data_o),
    .mem_oe_n           (ram_oe_n),
	.mem_we_n           (ram_we_n),
	.mem_be_n           (ram_be_n),
	.mem_ce_n           (ram_ce_n),

	.base_ram_data      (base_ram_data),
	.base_ram_addr      (base_ram_addr),
	.base_ram_be_n      (base_ram_be_n),
	.base_ram_ce_n      (base_ram_ce_n),
	.base_ram_oe_n      (base_ram_oe_n),
	.base_ram_we_n      (base_ram_we_n),

	.ext_ram_data       (ext_ram_data),
	.ext_ram_addr       (ext_ram_addr),
	.ext_ram_be_n       (ext_ram_be_n),
	.ext_ram_ce_n       (ext_ram_ce_n),
	.ext_ram_oe_n       (ext_ram_oe_n),
	.ext_ram_we_n       (ext_ram_we_n),
	
	.stall_inst         (stall_from_bus),
    .serial_i           (serial_i)
);


// bus_ctrl u_bus(
// 	.clk                (clk),  
// 	.rst                (rst),

// 	.inst_addr_i        (rom_addr_o),
// 	.rom_ce_n_i         (rom_ce_n),
// 	.inst_o             (inst_i),

// 	.ram_data_o         (ram_data_i),
// 	.mem_addr_i         (ram_addr_o),
// 	.mem_data_i         (ram_data_o),
//     .mem_oe_n           (ram_oe_n),
// 	.mem_we_n           (ram_we_n),
// 	.mem_be_n          (ram_be_n),
// 	.mem_ce_n           (ram_ce_n),

// 	.base_ram_data      (base_ram_data),
// 	.base_ram_addr      (base_ram_addr),
// 	.base_ram_be_n      (base_ram_be_n),
// 	.base_ram_ce_n      (base_ram_ce_n),
// 	.base_ram_oe_n      (base_ram_oe_n),
// 	.base_ram_we_n      (base_ram_we_n),

// 	.ext_ram_data       (ext_ram_data),
// 	.ext_ram_addr       (ext_ram_addr),
// 	.ext_ram_be_n       (ext_ram_be_n),
// 	.ext_ram_ce_n       (ext_ram_ce_n),
// 	.ext_ram_oe_n       (ext_ram_oe_n),
// 	.ext_ram_we_n       (ext_ram_we_n),
	
// 	.stall_from_bus     (stall_from_bus),
// 	.txd                (txd),
// 	.rxd                (rxd)
// );

endmodule
