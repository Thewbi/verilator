module top(
	input	logic           clk, reset,
	output 	logic [31:0] 	WriteData, DataAdr,
	output 	logic           MemWrite);
	
	logic [31:0] PC;
	logic [31:0] Instr;
	logic [31:0] ReadData;
	
	// instantiate processor and memories
	single_cycle_processor riscvsingle(clk, reset, PC, Instr, MemWrite, DataAdr,  WriteData, ReadData);
	instruction_memory imem(PC, Instr);
	data_memory dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
	
endmodule

