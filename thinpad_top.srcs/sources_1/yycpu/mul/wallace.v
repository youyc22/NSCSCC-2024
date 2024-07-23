
module wallace (
    input  wire [31:0]   mul1,    // 32位乘数1
    input  wire [31:0]   mul2,    // 32位乘数2
    output wire [63:0]   result   // 64位乘法结果
);

wire        [ 2:0]   booth_code  [15:0];  // 16个3位Booth编码
wire        [31:0]   mulX;                // 乘数X（mul1）
wire        [32:0]   mulX_2;              // 乘数X左移1位
wire        [31:0]   mulX_com;            // 乘数X的反码
wire        [32:0]   mulX_com_2;          // 乘数X反码左移1位
wire        [31:0]   mulY;                // 乘数Y（mul2）
wire        [63:0]   Nsum       [15:0];   // 16个64位部分积
wire        [64:0]   Csum       [16:0];   // 17个65位进位和
wire        [63:0]   Ssum       [16:0];   // 17个64位部分和

// 初始化变量
assign mulX         = mul1;
assign mulX_2       = mulX<<1;
assign mulX_com     = ~mulX;
assign mulX_com_2   = ~ (mulX<<1);
assign mulY         = mul2;

// 生成Booth编码
genvar i;
generate
    assign booth_code[0] = {mulY[1], mulY[0], 1'b0};
    for (i = 1; i< 16; i = i + 1) begin
        assign booth_code[i] = {mulY[2*i+1], mulY[2*i], mulY[2*i-1]};
    end
endgenerate

// 生成部分积和进位
generate
    for (i = 0; i < 16; i = i + 1) begin
        // 根据Booth编码生成部分积
        assign Nsum[i] = {64{(booth_code[i] == 3'b000)}} & 64'b0 |
                         {64{(booth_code[i] == 3'b001)}} & {{(32-2*i){mulX[31]}},         mulX,       {2*i{1'b0}}} |
                         {64{(booth_code[i] == 3'b010)}} & {{(32-2*i){mulX[31]}},         mulX,       {2*i{1'b0}}} |
                         {64{(booth_code[i] == 3'b011)}} & {{(32-2*i-1){mulX_2[32]}},     mulX_2,     {2*i{1'b0}}} |
                         {64{(booth_code[i] == 3'b100)}} & {{(32-2*i-1){mulX_com_2[32]}}, mulX_com_2, {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b101)}} & {{(32-2*i){mulX_com[31]}},     mulX_com,   {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b110)}} & {{(32-2*i){mulX_com[31]}},     mulX_com,   {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b111)}} & 64'b0;
        // 生成进位
        assign Csum[i][0] = (booth_code[i] == 3'b100) |
                            (booth_code[i] == 3'b101) |
                            (booth_code[i] == 3'b110) ;
    end
endgenerate

// 初始化最后一个进位为0
assign Csum[16][0] = 1'b0;

// Wallace树压缩
generate 
    for(i=0;i<64;i=i+1)begin
        //第一层
        adder  adder0(.Add_A(Nsum[  0][i]),.Add_B(Nsum[  1][i]),.Add_Cin(Nsum[  2][i]),.Sum(Ssum[ 0][i]),.Cout(Csum[ 0][i+1]));
        adder  adder1(.Add_A(Nsum[  3][i]),.Add_B(Nsum[  4][i]),.Add_Cin(Nsum[  5][i]),.Sum(Ssum[ 1][i]),.Cout(Csum[ 1][i+1]));
        adder  adder2(.Add_A(Nsum[  6][i]),.Add_B(Nsum[  7][i]),.Add_Cin(Nsum[  8][i]),.Sum(Ssum[ 2][i]),.Cout(Csum[ 2][i+1]));
        adder  adder3(.Add_A(Nsum[  9][i]),.Add_B(Nsum[ 10][i]),.Add_Cin(Nsum[ 11][i]),.Sum(Ssum[ 3][i]),.Cout(Csum[ 3][i+1]));
        adder  adder4(.Add_A(Nsum[ 12][i]),.Add_B(Nsum[ 13][i]),.Add_Cin(Nsum[ 14][i]),.Sum(Ssum[ 4][i]),.Cout(Csum[ 4][i+1]));
        adder  adder5(.Add_A(Nsum[ 15][i]),.Add_B(1'b0        ),.Add_Cin(1'b0        ),.Sum(Ssum[ 5][i]),.Cout(Csum[ 5][i+1]));
        //第二层
        adder  adder6(.Add_A(Ssum[  0][i]),.Add_B(Ssum[  1][i]),.Add_Cin(Ssum[  2][i]),.Sum(Ssum[ 6][i]),.Cout(Csum[ 6][i+1]));
        adder  adder7(.Add_A(Ssum[  3][i]),.Add_B(Ssum[  4][i]),.Add_Cin(Ssum[  5][i]),.Sum(Ssum[ 7][i]),.Cout(Csum[ 7][i+1]));
        adder  adder8(.Add_A(Csum[  0][i]),.Add_B(Csum[  1][i]),.Add_Cin(Csum[  2][i]),.Sum(Ssum[ 8][i]),.Cout(Csum[ 8][i+1]));
        adder  adder9(.Add_A(Csum[  3][i]),.Add_B(Csum[  4][i]),.Add_Cin(Csum[  5][i]),.Sum(Ssum[ 9][i]),.Cout(Csum[ 9][i+1]));
        //第三层
        adder adder10(.Add_A(Ssum[  6][i]),.Add_B(Ssum[  7][i]),.Add_Cin(Ssum[  8][i]),.Sum(Ssum[10][i]),.Cout(Csum[10][i+1]));
        adder adder11(.Add_A(Ssum[  9][i]),.Add_B(Csum[  6][i]),.Add_Cin(Csum[  7][i]),.Sum(Ssum[11][i]),.Cout(Csum[11][i+1]));
        adder adder12(.Add_A(Csum[  8][i]),.Add_B(Csum[  9][i]),.Add_Cin(1'b0        ),.Sum(Ssum[12][i]),.Cout(Csum[12][i+1]));
        //第四层
        adder adder13(.Add_A(Ssum[ 10][i]),.Add_B(Ssum[ 11][i]),.Add_Cin(Ssum[ 12][i]),.Sum(Ssum[13][i]),.Cout(Csum[13][i+1]));
        adder adder14(.Add_A(Csum[ 10][i]),.Add_B(Csum[ 11][i]),.Add_Cin(Csum[ 12][i]),.Sum(Ssum[14][i]),.Cout(Csum[14][i+1]));
        //第五层
        adder adder15(.Add_A(Ssum[ 13][i]),.Add_B(Ssum[ 14][i]),.Add_Cin(Csum[ 13][i]),.Sum(Ssum[15][i]),.Cout(Csum[15][i+1]));
        //第六层
        adder adder16(.Add_A(Ssum[ 15][i]),.Add_B(Csum[ 14][i]),.Add_Cin(Csum[ 15][i]),.Sum(Ssum[16][i]),.Cout(Csum[16][i+1]));
    end
endgenerate

// 计算最终结果
assign result = Ssum[16] + Csum[16][63:0];

endmodule