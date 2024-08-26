module single_cycle_processor(
	input   logic        	clk, reset,
	output	logic   [31:0]  PC,
	input   logic   [31:0]  Instr,
	output  logic       	MemWrite,
	output  logic  	[31:0]  ALUResult, WriteData,
	input   logic  	[31:0] 	ReadData);
					
	logic   	ALUSrc;
	logic 		PCSrc; // determines, which input is muxed into the PC (Program Counter). Either a jump target or PC+4
	logic 		RegWrite;
	logic 		Jump;
	logic 		Zero;
	logic [1:0] ResultSrc, ImmSrc;
	logic [2:0] ALUControl;
	
	controller controller(Instr[6:0], Instr[14:12], Instr[30], Zero,
		ResultSrc, MemWrite, PCSrc,
		ALUSrc, RegWrite, Jump,
		ImmSrc, ALUControl);

	datapath data_path(clk, reset, ResultSrc, PCSrc,
		ALUSrc, RegWrite,
		ImmSrc, ALUControl,
		Zero, PC, Instr,
		ALUResult, WriteData, ReadData);

endmodule
