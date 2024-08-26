module register_file(
	input  logic   			clk, // clk
	input  logic   			we3, // write enable. This enables the write operation. The read operation is always active!
	input  logic  	[4:0]  	a1, a2, // addresses of the registers with addresses a1 and a2 to read from (a1 -> read -> rd1); (a2 -> read -> rd2);
	input  logic  	[4:0]	a3, // address of the register to write into
	input  logic  	[31:0] 	wd3, // value to write into register with address a3 (a3 -> write -> wd3);
	output logic	[31:0] 	rd1, rd2); // registers values are output here

	logic [31:0] rf[31:0];
	
	// three ported register file
	// read two ports combinationally (A1/RD1, A2/RD2)
	// write third port on rising edge of clock (A3/WD3/WE3)
	// register 0 hardwired to 0
	always_ff @(posedge clk)
		if (we3) 
			rf[a3] <= wd3;
		assign rd1 = (a1 != 0) ? rf[a1] : 0;
		assign rd2 = (a2 != 0) ? rf[a2] : 0;

endmodule

