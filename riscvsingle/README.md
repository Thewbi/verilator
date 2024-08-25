# Credit

Harris & Harris - Digital Design and Computer Architecture RISC-V edition-

## Building

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