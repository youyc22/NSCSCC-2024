
module adder (
   input wire  Add_A,
   input wire  Add_B,
   input wire  Add_Cin,
   output wire Cout,
   output wire Sum
);

assign Cout = (Add_A & Add_B) | (Add_Cin & (Add_A | Add_B));
assign Sum  = Add_A ^ Add_B ^ Add_Cin;

endmodule
