VERILATOR_ROOT := /home/wbi/dev/verilator/verilator

all: sim_main.cpp \
    top.sv \
	common.sv \
    single_cycle_processor.sv \
    instruction_memory.sv \
    data_memory.sv \
    mux2.sv \
    mux3.sv \
    adder.sv \
    alu_decoder.sv \
	alu.sv \
    controller.sv \
    datapath.sv \
    extend_unit.sv \
    flipflop_with_reset_and_enable.sv \
	flipflop_with_reset.sv \
    main_decoder.sv \
    register_file.sv \
    rom.sv
	$(VERILATOR_ROOT)/bin/verilator --cc --exe -CFLAGS -g --build -j 1 -Wall -Wno-UNUSEDSIGNAL --top-module top sim_main.cpp \
    top.sv \
    common.sv \
    single_cycle_processor.sv \
    instruction_memory.sv \
    data_memory.sv \
    mux2.sv \
    mux3.sv \
    adder.sv \
    alu_decoder.sv \
    alu.sv \
    controller.sv \
    datapath.sv \
    extend_unit.sv \
    flipflop_with_reset_and_enable.sv \
    flipflop_with_reset.sv \
    main_decoder.sv \
    register_file.sv \
    rom.sv