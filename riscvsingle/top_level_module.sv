module top(
	input	logic           clk, reset,
	output 	logic [31:0] 	WriteData, DataAdr,
	output 	logic           MemWrite
	);
	
	logic [31:0] PC;
	logic [31:0] Instr;
	logic [31:0] ReadData;
	
	// instantiate processor and memories
	riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr,  WriteData, ReadData);
	imem imem(PC, Instr);
	dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
	
endmodule