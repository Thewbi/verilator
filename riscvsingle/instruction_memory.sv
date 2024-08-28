module instruction_memory(
	input   logic [31:0] a,
	output  logic [31:0] rd);

    logic [31:0] RAM[63:0];

    initial begin
        $readmemh("riscvtest.txt", RAM);
    end

    assign rd = RAM[a[7:2]]; // word aligned

endmodule
