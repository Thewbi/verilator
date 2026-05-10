# Building

## Install verilator via msys2.

Open the msys2 64 bit console.

```
pacman -S mingw-w64-x86_64-verilator
```

## Generate a C++ application from the verilog file

You need to provide a tb_gates.cpp testbench file.

// verilator --cc gates.sv -Wno-ENUMVALUE
// verilator --cc --exe --build -j 1 -Wall -Wno-ENUMVALUE --trace tb_gates.cpp gates.sv
// make -C obj_dir -f Vgates.mk Vgates
// verilator -Wall -Wno-ENUMVALUE --trace -cc gates --exe tb_gates.cpp

```
cd /c/Users/lapto/dev/fpga/verilator/gates
verilator --cc --exe --build -j 1 -Wall -Wno-ENUMVALUE --trace tb_gates.cpp gates.sv
```

## Running the .exe file

To run the simulation, run the .exe file that verilator has generated.
The simulation will write out a trace file that can be viewed using GTKWave for example.

```
obj_dir/Vgates.exe
```

The trace file is located in the current working directory

## Open GTKWave on the trace file

You only need to open GTKWave on the trace file once, you can then reload after new waveforms.vcd files have been generated.

```
gtkwave --rcfile ./.gtkwaverc -f waveform.vcd &
```

## Makefile

```
make clean
make
make waves
```

## Disable splash screen

Create a local .gtkwaverc file:

```
splash_disable 1
```

Use this file as config file when starting gtkwave:

```
gtkwave --rcfile ./.gtkwaverc -f waveform.vcd &
```