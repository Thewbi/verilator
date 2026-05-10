#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vgates.h"
//#include "Valu___024unit.h"

// export VERILATOR_ROOT=/home/wbi/dev/verilator/verilator
// export PATH=$VERILATOR_ROOT/bin:$PATH
//
// verilator --cc alu.sv -Wno-ENUMVALUE
// verilator --cc --exe --build -j 1 -Wall -Wno-ENUMVALUE --trace tb_alu.cpp alu.sv
// make -C obj_dir -f Valu.mk Valu
// gtkwave waveform.vcd

// or build using the provided Makefile
//
// make & make waves

// these signals are of interest in gtk wave
// a_in[5:0]
// b_in[5:0]
// op_in[1:0]
// in_valid
// out[5:0]
// out_valid

// https://veripool.org/guide/latest/faq.html
double sc_time_stamp() { return 0; }

#define MAX_SIM_TIME 100
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {

    Vgates *dut = new Vgates;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;

    dut->trace(m_trace, 5);

    m_trace->open("waveform.vcd");

    while (sim_time < MAX_SIM_TIME) {

        //dut->rst = 0;

        // reset during ]1, 5[
        if (sim_time > 1 && sim_time <= 5) {
        //     dut->rst = 1;
        //     dut->a_in = 0;
        //     dut->b_in = 0;
        //     dut->op_in = 0;
        //     dut->in_valid = 0;

            dut->a = 0;
            dut->b = 0;
        }

        // add during ]5, 10[
        else if (sim_time > 5 && sim_time <= 10) {
        //     dut->a_in = 1;
        //     dut->b_in = 0;
        //     dut->op_in = Valu___024unit::operation_t::add;
        //     dut->in_valid = 1;

            dut->a = 1;
            dut->b = 0;
        }

        // add during ]10, 15[
        else if (sim_time > 10 && sim_time <= 15) {
        //     dut->a_in = 5;
        //     dut->b_in = 3;
        //     dut->op_in = Valu___024unit::operation_t::sub;
        //     dut->in_valid = 1;

            dut->a = 0;
            dut->b = 1;
        }

        // add during ]15, 20[
        else if (sim_time > 15 && sim_time <= 20) {
        //     dut->a_in = 5;
        //     dut->b_in = 3;
        //     dut->op_in = Valu___024unit::operation_t::sub;
        //     dut->in_valid = 1;

            dut->a = 1;
            dut->b = 1;
        }
        else {
            dut->a = 0;
            dut->b = 0;
        }

        // dut->clk ^= 1;

        // recompute values
        dut->eval();

        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();

    delete dut;
    dut = NULL;

    exit(EXIT_SUCCESS);
}
