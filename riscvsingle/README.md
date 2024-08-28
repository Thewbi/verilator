# Credit

Harris & Harris - Digital Design and Computer Architecture RISC-V edition-

## Building

Run the makefile

```
make
```

Set up environment variables:

```
export VERILATOR_ROOT=/home/wbi/dev/verilator/verilator
export PATH=$VERILATOR_ROOT/bin:$PATH
```

Compile the system verilog source:
This command performs compilation and C++ generation and
it compiles your driver (main file that runs the simulation) with the 
generated code into a binary.

```
verilator --cc --exe --build -j 1 -Wall sim_main.cpp \
    top_level_module.sv \
    single_cycle_processor.sv \
    instruction_memory.sv \
    data_memory.sv \
    mux_2to1.sv \
    mux_3to1.sv \
    adder.sv \
    alu_decoder.sv \
    controller.sv \
    datapath.sv \
    extend_unit.sv \
    flipflop_with_reset_and_enable.sv \
    main_decoder.sv \
    regtile.sv \
    rom.sv
```

# Writing a Image into Instruction Memory

After assembling the source code is available as a block of bytes representing
the machine code. The bytes have to be written into the instruction memory so
that the CPU can fetch the curren instruction in each cycle.

Verilog has a $readmemh() instruction that is not synthesizable but can be used
for simulation. Verilator implements the $readmemh() instruction. Therefore
it is possible to load a sample application into instruction memory.

The instruction_memory.sv file contains the call to $readmemh() and executes it
in a initial block.

```
module instruction_memory(
	input   logic [31:0] a,
	output  logic [31:0] rd);

    logic [31:0] RAM[63:0];

    initial begin
        $readmemh("riscvtest.txt", RAM);
    end

    assign rd = RAM[a[7:2]]; // word aligned

endmodule
```

When the file is specified like this, then it is expected in the current
working directory (pwd) when executing the compiled verilator binary.

The riscvtest.txt file has to be provided by the user. A sample file 
may look like this:

```
00500113
00C00193
FF718393
0023E233
0041F2B3
004282B3
02728863
0041A233
00020463
00000293
0023A233
005203B3
402383B3
0471AA23
06002103
005104B3
008001EF
00100113
00910133
0221A023
00210063
```

Verilator will place the bytes into the RAM variable as specified in the 
call to $readmemh(). It starts at index zero and fills the RAM variable 
with bytes. To prevent errors, make sure to not add more bytes into the
testfile.txt than fit into the RAM variable.

If the file cannot be found or there is too much data to fit into the
target variable, the compiled verilator binary will print errors on startup.
Keep an eye on the console and look for any errors.

In order to check if the data really has been loaded into the instruction
memory, the instruction memory can be printed to the console using a C++
for loop:

```
// DEBUG output instruction memory
std::cout << "\nInstruction Memory\n";
VlUnpacked<IData/*31:0*/, 64> instruction_memory = top->rootp->top__DOT__imem__DOT__RAM;
for (size_t i = 0; i < 64; i++) {
    IData cell = instruction_memory[i];
    std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << cell << "\n";
}
```

This loop produces almost the same output that is also stored inside the riscvtest.txt.

# Fetching The Next Instruction from Memory

Inside top.sv, the instruction_memory is instantiated.
As an address, the PC is used. The output parameter is connected with the
Instr variable which is also used as an input to the riscv CPU.

Looking into instruction_memory.sv reveals that this module is very simple.
It is not clocked, instead it is purely combinational. 
Applying an address will return the instruction at that address through the
output parameter.

The pure fact that the instruction_memory is instantiated in the top-level
module causes the instructions to be fetched.