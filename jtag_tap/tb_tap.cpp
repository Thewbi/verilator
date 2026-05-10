#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtap.h"
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

void step(Vtap *dut, VerilatedVcdC *m_trace) {
    dut->tck ^= 1;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;

    dut->tck ^= 1;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
}

void step_without_clock(Vtap *dut, VerilatedVcdC *m_trace) {
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
}

int main(int argc, char** argv, char** env) {

    Vtap *dut = new Vtap;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;

    dut->trace(m_trace, 5);

    m_trace->open("waveform.vcd");

    // while (sim_time < MAX_SIM_TIME) {

    //     //dut->rst = 0;

    //     // reset during ]1, 5[
    //     if (sim_time >= 0 && sim_time <= 4) {
    //         dut->trst = 1;
    //         dut->tms = 0;
    //     }
    //     // reset state machine via transition back to TEST_LOGIC_RESET during ]5, 10[
    //     else if (sim_time > 4 && sim_time <= 9) {
    //         dut->trst = 0;
    //         dut->tms = 1;
    //     }
    //     // reset state machine via transition back to TEST_LOGIC_RESET  during ]10, 15[
    //     else if (sim_time > 9 && sim_time <= 14) {
    //         dut->trst = 0;
    //         dut->tms = 1;
    //     }

    //     // ?? during ]15, 20[
    //     else if (sim_time > 14 && sim_time <= 19) {
    //         dut->tms = 1;
    //     }

    //     // rest of the simulation
    //     else {
    //         dut->trst = 1;
    //         dut->tms = 0;
    //     }

    //     // toggle clock
    //     dut->tck ^= 1;

    //     // recompute values
    //     dut->eval();

    //     m_trace->dump(sim_time);
    //     sim_time++;
    // }

    // reset via reset signal
    while (sim_time < 10) {
        dut->trst = 1;
        dut->tms = 0;

        step(dut, m_trace);
    }

    // reset state machine via transition back to TEST_LOGIC_RESET
    while (sim_time < 20) {
        dut->trst = 0;
        dut->tms = 1;

        step(dut, m_trace);
    }

    // do nothing
    while (sim_time < 30) {
        dut->trst = 0;
        dut->tms = 0;

        step_without_clock(dut, m_trace);
    }

    //
    // shift DR
    //

    // tms=1
    dut->tms = 1; step_without_clock(dut, m_trace);
    dut->tms = 1; step(dut, m_trace);

    // tms=1
    dut->tms = 1; step(dut, m_trace);

    // tms=1
    dut->tms = 1; step(dut, m_trace);

    // tms=0
    dut->tms = 0; step_without_clock(dut, m_trace);
    dut->tms = 0; step(dut, m_trace);

    // tms=0
    dut->tms = 1; step_without_clock(dut, m_trace);
    dut->tms = 1; step(dut, m_trace);

    // tms=0
    dut->tms = 0; step_without_clock(dut, m_trace);
    dut->tms = 0; step(dut, m_trace);

    // tms=0
    dut->tms = 0; step(dut, m_trace);

    dut->tms = 0; dut->tdi = 1; step(dut, m_trace);


    // finish simulation
    while (sim_time < MAX_SIM_TIME) {
       step(dut, m_trace);
    }

    m_trace->close();

    delete dut;
    dut = NULL;

    exit(EXIT_SUCCESS);
}
