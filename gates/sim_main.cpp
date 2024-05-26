#include "obj_dir/Vgates.h"
#include "verilated.h"

// Install from package management (apt has very old verilator packages which
// will not work with most examples and tutorials found on the internet)
// It is recommended to install verilator from source
//
// sudo apt-get install verilator




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
// verilator -V
//
// first, clean the content of the obj_dir folder to get rid of old files
//
// # The --cc parameter here tells Verilator to convert to C++. Use --sc for SystemC.
// verilator --cc gates.v
// verilator --cc --exe --build -j 1 -Wall sim_main.cpp gates.v
//
// The result is the executable:
// ./obj_dir/Vgates

int main(int argc, char** argv) {

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    Vgates* top = new Vgates{contextp};

    top->
    while (!contextp->gotFinish()) { 
        top->eval(); 
    }

    delete top;
    delete contextp;

    return 0;
}