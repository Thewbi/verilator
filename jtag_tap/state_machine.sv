package state_machine;

    // https://www.xjtag.com/about-jtag/jtag-a-technical-overview/
    // https://openocd.org/doc/html/JTAG-Commands.html
    typedef enum logic [3:0] {

        TEST_LOGIC_RESET, // 0
        RUN_TEST_IDLE, // 1

        SELECT_DR, // 2
        CAPTURE_DR, // 3
        SHIFT_DR, // 4
        EXIT_1_DR, // 5
        PAUSE_DR, // 6
        EXIT_2_DR, // 7
        UPDATE_DR, // 8

        SELECT_IR, // 9
        CAPTURE_IR, // 10
        SHIFT_IR, // 11
        EXIT_1_IR, // 12
        PAUSE_IR, // 13
        EXIT_2_IR, // 14
        UPDATE_IR // 15

    } states_t;

endpackage
