// sudo apt-get install verilator
//
// Compile from git
//
// sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache
// sudo apt-get install libgoogle-perftools-dev numactl perl-doc
// sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
// sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
// sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)
//
// git clone https://github.com/verilator/verilator   # Only first time
//
// # Every time you need to build:
// unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
// unset VERILATOR_ROOT  # For bash
//
// cd verilator
// git pull         # Make sure git repository is up-to-date
// git tag          # See what versions exist
// git checkout master      # Use development branch (e.g. recent bug fixes)
// git checkout stable      # Use most recent stable release
// git checkout v{version}  # Switch to specified release version
//
// git checkout v5.024
//
// autoconf         # Create ./configure script
//
// Our personal favorite is to always run Verilator in-place from its Git
// directory (don’t run make install). This allows the easiest experimentation
// and upgrading, and allows many versions of Verilator to co-exist on a system.
//
// export VERILATOR_ROOT=`pwd`   # if your shell is bash
// setenv VERILATOR_ROOT `pwd`   # if your shell is csh
// ./configure      # Configure and create Makefile
// # Running will use files from $VERILATOR_ROOT, so no install needed
//
//
// make -j `nproc`  # Build Verilator itself (if error, try just 'make')
//
// # make install is not needed if you have executed: export VERILATOR_ROOT=`pwd`
// # with VERILATOR_ROOT=`pwd` you are saying, use verilator from the git repository
// # instaed of a installed version!
// sudo make install

//
//
// export VERILATOR_ROOT=/home/wbi/dev/verilator/verilator
// export PATH=$VERILATOR_ROOT/bin:$PATH
//
// -- output the verilator version
// verilator -V
//
// first, clean the content of the obj_dir folder to get rid of old files
//
// -- First, compile the verilog file to C++ files stored into the obj_dir folder
// verilator --cc top.v
//
// -- This command performs compilation and C++ generation and
// -- it compiles your driver (main file that runs the simulation) with the
// -- generated code into a binary
// verilator --cc --exe --build -j 1 -Wall sim_main.cpp top.v
//
// The result is the executable:
// obj_dir/Vtop

#include <iostream>
#include <iomanip>

#include "obj_dir/Vtop.h"
#include "verilated.h"
#include "obj_dir/Vtop___024root.h"
#include "obj_dir/Vtop_common.h"

int main(int argc, char **argv)
{
    //Vtop__Syms* commonSyms = top->__PVT__common->vlSymsp;

    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    Vtop *top = new Vtop{contextp};
    while (!contextp->gotFinish())
    {
        

        IData pc = top->rootp->top__DOT__PC;
        //top->__PVT__common;
        
        // top->reset = 1;

        // for (int i = 0; i < 5; i++) {

        //     top->clk = 1;
        //     top->eval();

        //     // DEBUG output register file
        //     std::cout << "\nRegister File\n";
        //     VlUnpacked<IData/*31:0*/, 32> register_file = top->rootp->top__DOT__riscvsingle__DOT__data_path__DOT__register_file__DOT__rf;
        //     for (size_t i = 0; i < 32; i++) {
        //         IData riscv_register = register_file[i];
        //         std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << riscv_register << "\n";
        //     }

        //     top->clk = 0;
        //     top->eval();

        //     register_file = top->rootp->top__DOT__riscvsingle__DOT__data_path__DOT__register_file__DOT__rf;
        //     for (size_t i = 0; i < 32; i++) {
        //         IData riscv_register = register_file[i];
        //         std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << riscv_register << "\n";
        //     }
        // }

        top->reset = 0;

        // DEBUG output instruction memory
        std::cout << "\nInstruction Memory\n";
        VlUnpacked<IData/*31:0*/, 64> instruction_memory = top->rootp->top__DOT__imem__DOT__RAM;
        for (size_t i = 0; i < 64; i++) {
            IData cell = instruction_memory[i];
            std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << cell << "\n";
        }

        // DEBUG output register file
        std::cout << "\nRegister File\n";
        VlUnpacked<IData/*31:0*/, 32> register_file = top->rootp->top__DOT__riscvsingle__DOT__data_path__DOT__register_file__DOT__rf;
        for (size_t i = 0; i < 32; i++) {
            IData riscv_register = register_file[i];
            std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << riscv_register << "\n";
        }

        // DEBUG output program counter
        pc = top->rootp->top__DOT__PC;
        std::cout << "pc: " << pc << "\n";

        // DEBUG output ALU control
        CData/*2:0*/ alu_control = top->rootp->top__DOT__riscvsingle__DOT__ALUControl;
        std::cout << "alu_control: " << std::to_string(alu_control) << "\n";

        for (int i = 0; i < 22; i++) {

            top->clk = 1;
            top->eval();

            top->clk = 0;
            top->eval();

            // DEBUG output register file
            std::cout << "\nRegister File\n";
            VlUnpacked<IData/*31:0*/, 32> register_file = top->rootp->top__DOT__riscvsingle__DOT__data_path__DOT__register_file__DOT__rf;
            for (size_t i = 0; i < 32; i++) {
                IData riscv_register = register_file[i];
                std::cout << std::dec << i << ": " << std::hex << std::setfill('0') << std::setw(8) << std::uppercase << riscv_register << "\n";
            }

            // DEBUG output program counter
            pc = top->rootp->top__DOT__PC;
            std::cout << "pc: " << pc << "\n";

            // DEBUG output ALU control
            CData/*2:0*/ alu_control = top->rootp->top__DOT__riscvsingle__DOT__ALUControl;
            std::cout << "alu_control: " << std::to_string(alu_control) << "\n";
        }
    }

    delete top;
    delete contextp;

    return 0;
}