module uart_controller (
    input wire          clk,
    input wire          rst,
    
    input wire [31:0]   mem_data_i,
    input wire [31:0]   mem_addr_i,
    input wire          mem_oe_n,
    input wire          mem_we_n,
    
    output reg [31:0]   serial_o,
    output wire         txd,
    input  wire         rxd
);

    parameter clk_freq = 118*1000000;
    parameter baud = 9600;
    
    reg [7:0] TxD_data;
    reg TxD_start;

    wire [7:0] RxD_data;
    wire RxD_data_ready;
    wire TxD_busy;
    wire RxD_clear;
    wire is_SerialState = (mem_addr_i == 32'hBFD003FC);
    wire is_SerialData  = (mem_addr_i == 32'hBFD003F8);

    assign RxD_clear = RxD_data_ready && is_SerialData && ~mem_oe_n;

    async_receiver #(.ClkFrequency(clk_freq),.Baud(baud))   
        ext_uart_r(
            .clk(clk),                           
            .RxD(rxd),                           
            .RxD_data_ready(RxD_data_ready),     
            .RxD_clear(RxD_clear),               
            .RxD_data(RxD_data)                  
        );

    async_transmitter #(.ClkFrequency(clk_freq),.Baud(baud)) 
        ext_uart_t(
            .clk(clk),                           
            .TxD(txd),                            
            .TxD_busy(TxD_busy),              
            .TxD_start(TxD_start),            
            .TxD_data(TxD_data)               
        );

    always @(*) begin
        TxD_start = 1'b0;
        serial_o = 32'h0;
        TxD_data = 8'h00;
        if(is_SerialState) begin                                     
            serial_o = {30'd0, {RxD_data_ready, ~TxD_busy}};
        end else if(is_SerialData) begin                  
            if(~mem_oe_n) begin
                serial_o = {24'd0, RxD_data};
            end else if(~TxD_busy && ~mem_we_n)begin
                TxD_data = mem_data_i[7:0];
                TxD_start = 1'b1;
            end
        end
    end

endmodule
