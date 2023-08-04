module SingleCycle(clk,  PC,  readIWire, readDataA, readDataB, resultALU, writeData, readDataMem, RegDst, Jump,
 BranchEq, BranchNeq, BranchLt, BranchGt, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite, alu_src, operation, sign_extend_imd, regDest, 
 jumpAdress, branchAdress, branchResult, isBranch, PCBranch, PCinput, zeroALU, ltALU, gtALU);

input clk;
output reg [15:0]PC;
wire [15:0]pcwire;
assign pcwire = PC;

output wire RegDst, Jump, BranchEq, BranchNeq, BranchLt, BranchGt, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite;
wire[2:0] ALUOp;

initial begin
	PC <= 0;
end

output wire [15:0] readIWire;

IMemBank IMemBank_inst
(
	.memread(1'b1) ,	// input  memread_sig
	.address(pcwire) ,	// input [7:0] address_sig
	.readdata(readIWire) 	// output [15:0] readdata_sig
);

controlUnit controlUnit_inst
(
	.opCode(readIWire[15:12]) ,	// input [3:0] opCode_sig
	.regDest(RegDst) ,	// output  regDest_sig
	.jump(Jump) ,	// output  jump_sig
	.BranchEq(BranchEq) ,	// output  BranchEq_sig
	.BranchNeq(BranchNeq) ,	// output  BranchNeq_sig
	.BranchGt(BranchGt) ,	// output  BranchGt_sig
	.BranchLt(BranchLt) ,	// output  BranchLt_sig
	.memRead(MemRead) ,	// output  memRead_sig
	.memToReg(MemToReg) ,	// output  memToReg_sig
	.ALUop(ALUOp[2:0]) ,	// output [2:0] ALUop_sig
	.memWrite(MemWrite) ,	// output  memWrite_sig
	.ALUsrc(ALUSrc) ,	// output  ALUsrc_sig
	.RegWrite(RegWrite) 	// output  RegWrite_sig
);



output wire[2:0] regDest;

mux2_1N3 mux2_1N3_Dest
(
	.data1(readIWire[8:6]) ,	// input [2:0] data1_sig
	.data2(readIWire[5:3]) ,	// input [2:0] data2_sig
	.sel(RegDst) ,	// input sel_sig
	.out(regDest) 	// output [2:0] out_sig
);




output wire[15:0] writeData, readDataA, readDataB;

RegFile RegFile_inst
(
	.clk(clk) ,	// input  clk_sig
	.readreg1(readIWire[11:9]) ,	// input [2:0] readreg1_sig
	.readreg2(readIWire[8:6]) ,	// input [2:0] readreg2_sig
	.writereg(regDest) ,	// input [2:0] writereg_sig
	.writedata(writeData) ,	// input [15:0] writedata_sig
	.RegWrite(RegWrite) ,	// input  RegWrite_sig
	.readdata1(readDataA) ,	// output [15:0] readdata1_sig
	.readdata2(readDataB) 	// output [15:0] readdata2_sig
);

output wire [15:0]sign_extend_imd;

sign_extend sign_extend_Imdiate
(
	.in(readIWire[5:0]) ,	// input in_sig
	.out(sign_extend_imd) 	// output out_sig
);

output wire [15:0]alu_src;

mux2_1N16 mux2_1N16_AluSrc
(
	.data1(readDataB) ,	// input [16:0] data1_sig
	.data2(sign_extend_imd) ,	// input [16:0] data2_sig
	.sel(ALUSrc) ,	// input  sel_sig
	.out(alu_src) 	// output [16:0] out_sig
);

output wire [3:0]operation;

ALUControl ALUControl_inst
(
	.ALUop(ALUOp) ,	// input [2:0] ALUop_sig
	.func(readIWire[2:0]) ,	// input [2:0] func_sig
	.aluoperation(operation) 	// output [3:0] aluoperation_sig
);

output wire [15:0] resultALU;
output wire zeroALU, ltALU, gtALU;

ALU ALU_inst
(
	.data1(readDataA) ,	// input [15:0] data1_sig
	.data2(alu_src) ,	// input [15:0] data2_sig
	.aluoperation(operation) ,	// input [3:0] aluoperation_sig
	.result(resultALU) ,	// output [15:0] result_sig
	.zero(zeroALU) ,	// output  zero_sig
	.lt(ltALU) ,	// output  lt_sig
	.gt(gtALU) 	// output  gt_sig
);

output wire [15:0]readDataMem;

DMemBank DMemBank_inst
(
	.clk(clk) ,	//	input clk
	.memread(MemRead) ,	// input  memread_sig
	.memwrite(MemWrite) ,	// input  memwrite_sig
	.address(resultALU) ,	// input [15:0] address_sig
	.writedata(readDataB) ,	// input [15:0] writedata_sig
	.readdata(readDataMem) 	// output [15:0] readdata_sig
);


mux2_1N16 mux2_1N16_writeData
(
	.data1(resultALU) ,	// input [15:0] data1_sig
	.data2(readDataMem) ,	// input [15:0] data2_sig
	.sel(MemToReg) ,	// input  sel_sig
	.out(writeData) 	// output [15:0] out_sig
);
//check *****************************************************************************************
reg[15:0] newPC;

always@(*)
	newPC = PC + 1;

output wire[15:0] jumpAdress, branchAdress;

assign jumpAdress = {PC[15:12], readIWire[11:0]};

output wire[15:0] branchResult;

adder adder_branch
(
	.a(newPC) ,	// input [15:0] a_sig
	.b(sign_extend_imd) ,	// input [15:0] b_sig
	//************************************************************
	.result(branchResult) 	// output [15:0] result_sig
);

output wire isBranch;
assign isBranch = (BranchEq & zeroALU) | (BranchNeq & ~zeroALU) | (BranchGt & gtALU) | (BranchLt & ltALU);
output wire [15:0]PCBranch;

mux2_1N16 mux2_1N16_Branch
(
	.data1(newPC) ,	// input [15:0] data1_sig
	.data2(branchResult) ,	// input [15:0] data2_sig
	.sel(isBranch) ,	// input  sel_sig
	.out(PCBranch) 	// output [15:0] out_sig
);

output wire [15:0]PCinput;

mux2_1N16 mux2_1N16_jump
(
	.data1(PCBranch) ,	// input [15:0] data1_sig
	.data2(jumpAdress) ,	// input [15:0] data2_sig
	.sel(Jump) ,	// input  sel_sig
	.out(PCinput) 	// output [15:0] out_sig
);

always @(negedge clk)
	PC <= PCinput;

endmodule





