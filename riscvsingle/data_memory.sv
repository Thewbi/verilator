 module data_memory(
	input   logic           clk,    // clock
    input   logic           we,     // write enable
	input   logic [31:0]    a,      // address
    input   logic [31:0]    wd,     // write data
	output  logic [31:0]    rd);    // read data

    // 64 words of data memory, each word is 32-bit
    // 64 elements can be indexed using 6 bit (2^6 = 64) therefore
    // the address has to be 6 bit
    logic [31:0] RAM[63:0];

    assign rd = RAM[a[7:2]]; // word aligned

    always_ff @(posedge clk)
        if (we) begin
			RAM[a[7:2]] <= wd;
            //RAM[6'b000000] <= 1; 
            $display("Writing data memory! Value: %d to address: %d", wd, a[7:0]);
            $display("Data memory: %d", RAM[a[7:2]]);
        end

 endmodule

