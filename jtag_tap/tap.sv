/* verilator lint_off UNUSEDSIGNAL */

// https://stackoverflow.com/questions/77736416/define-constant-from-expression
//`define IDCODE_IR_VALUE 32'hFFFFFFFF
`define IDCODE_IR_VALUE 32'h00000001
`define DTMCONTROL_IR_VALUE 32'h00000010 // RISC-V DTMCONTROL (Debug Transport Module Control) aka. dtmcs (Debug Transport Module Control and Status)
`define DMI_VALUE 32'h00000011

// `define DMCONTROL_IR_VALUE 32'h00000010

`define CHIP_IDCODE 32'h10e31913

module tap (

    input   logic tck, // JTAG clock
    input   logic tdi,
    output  logic tdo,
    input   logic tms,
    input   logic trst

);

    state_machine::states_t current_state;

    logic [31:0] shift_reg_32;
    logic [41:0] shift_reg_42;

    // JTAG TAP / RISC-V DTM registers (RISC-V External Debug Support Version 0.13.2, page 63)
    logic [31:0] baseline_register_ir;
    logic [31:0] baseline_register_idcode;      // 0x01 IDCODE
    logic [31:0] baseline_register_dtmcontrol;  // 0x10 DTM Control and Status (dtmcs), page 64
    logic [41:0] baseline_register_dmi;         // 0x11 Debug Module Interface Access (dmi), page 65

    // RISC-V DM registers (RISC-V External Debug Support Version 0.13.2, page 20)
    logic [31:0] baseline_register_data0;       // 0x04
    logic [31:0] baseline_register_data1;       // 0x05
    logic [31:0] baseline_register_dmcontrol;   // 0x10 (page 22, 23)
    logic [31:0] baseline_register_dmstatus;    // 0x11 (page 20, 21)
    logic [31:0] baseline_register_abstractcs;  // 0x16 (page 27, 28)
    logic [31:0] baseline_register_command;     // 0x17 (page 28)
    logic [31:0] baseline_register_sbcs;        // 0x38 (page 32)

    //initial begin
    //    $display("Hello World");
    //    $finish;
    //end

    logic tdo_reg;
    assign tdo = tdo_reg;

    always_ff @(posedge tck)
    begin

        //$display("IS state_machine::CAPTURE_DR shift_reg_32:%x", shift_reg_32);

        if (trst == 1) begin

            baseline_register_ir <= `IDCODE_IR_VALUE; // preselect the IDCODE baseline register on reset. This means shifting DR after a reset will produce the IDCODE of the target chip

            baseline_register_idcode <= `CHIP_IDCODE; // 0001 0000 1110 0011 0001 1001 0001 0011

            //
            // JTAG TAP == RISC-V DTM registers: (Page 63)
            //
            //
            // Address     Name                                    Description                             Page
            // ------------------------------------------------------------------------------------------------
            // 0x00        BYPASS                                  JTAG recommends this encoding
            // 0x01        IDCODE                                  JTAG recommends this encoding
            // 0x10        DTM Control and Status (dtmcs)          For Debugging                           64
            // 0x11        Debug Module Interface Access (dmi)     For Debugging                           65
            // 0x12        Reserved (BYPASS)                       Reserved for future RISC-V debugging
            // 0x13        Reserved (BYPASS)                       Reserved for future RISC-V debugging
            // 0x14        Reserved (BYPASS)                       Reserved for future RISC-V debugging
            // 0x15        Reserved (BYPASS)                       Reserved for future RISC-V standards
            // 0x16        Reserved (BYPASS)                       Reserved for future RISC-V standards
            // 0x17        Reserved (BYPASS)                       Reserved for future RISC-V standards
            // 0x1f        BYPASS                                  JTAG requires this encoding
            //

            // 6.1.4 DTM Control and Status (dtmcs, at 0x10), page 64
            // Part of the JTAG TAP
            //
            // DTMCONTROL (dtmcs) Register Layout (32-bit)
            //
            // The register consists of the following fields:
            // [31:22]: Reserved.
            // [21:20]: ackbusy (Write-only): Writing 1 to this bit clears the busy condition after a failed request.
            // [19:18]: busy (Read-only): 1 if the DTM is currently busy with a previous request.
            // [17:16]: idle (Read/Write): Number of TCK cycles to wait in the Run-Test/Idle state.
            // [15:12]: dmihardreset (Read/Write): Command to trigger a hard reset of the DMI.
            // [11:10]: dmireset (Read/Write): Resets the sticky error state (op != 0).
            // [9:4]: abits (Read-only): Number of address bits in the DMI register.
            // [3:0]: version (Read-only): Version of the DTM.
            //
            // 0xAAC30021 == 1010101011 00 00 11 0000 00 000010 0001
            baseline_register_dtmcontrol <= {
                10'b1010101011, // [31:22]: Reserved.
                2'b00, // [21:20]: ackbusy (Write-only): Writing 1 to this bit clears the busy condition after a failed request.
                2'b00, // [19:18]: busy (Read-only): 1 if the DTM is currently busy with a previous request.
                2'b11, // [17:16]: idle (Read/Write): Number of TCK cycles to wait in the Run-Test/Idle state.
                4'b0000, // [15:12]: dmihardreset (Read/Write): Command to trigger a hard reset of the DMI.
                2'b00, // dmireset (Read/Write): Resets the sticky error state (op != 0).
                6'b001000, // abits (Read-only): Number of address bits in the DMI register.
                4'b0001 // version
            };

            // 6.1.5 Debug Module Interface Access (dmi, at 0x11), page 65

            // abits+33:34     33:2    1:0
            // address         data    op
            // abits           32      2

            baseline_register_dmi <= {
                8'b00000000, // address bits (abits). Has to be the size as specified in the dtmcontrol.abits field
                32'b0, // data
                2'b00 // op (00: nop (ignore data and address), 01: Read from address. (read), 10: Write data to address. (write), 11: Reserved)
            };

            //
            // DM is the RISC-V Debug Module. It could be accessed over several technologies. Here JTAG is used. The JTAG TAP talks to the DM.
            //

            // 0x04
            baseline_register_data0 <= {
                32'b0
                //32'hdeadbeef
            };
            // 0x05
            baseline_register_data1 <= {
                32'b0
                //32'hcafebabe
            };

            //
            // DM.DMControl - https://riscv.org/wp-content/uploads/2024/12/riscv-debug-release.pdf, page 23
            // DO NOT CONFUSE WITH DTMCONTROL!!!!!!!
            //
            // Part of the RISC-V DM
            //

            // Explanation Format: first row: bit position, second row: fieldname, third row: field length in bits

            // 31      30          29          28              27  26      25-16       15-6        5-4     3                   2                   1           0
            // haltreq resumereq   hartreset   ackhavereset    0   hasel   hartsel lo  hartsel hi  00      setresethaltreq     clrresethaltreq     ndmreset    dmactive
            // 1       1           1           1               1   1       10          10          2       1                   1                   1           1

            // 0x10
            baseline_register_dmcontrol <= {
                1'b0, // [31] haltreq
                1'b0, // [30] resumereq
                1'b0, // [29] hartreset
                1'b0, // [28] ackhavereset
                1'b0, // [27] - fixed zero
                1'b0, // [26] hasel - An implementation which does not implement the hart array mask register must tie this field to 0.
                10'b0000000000, // [25:16] hartsel lo
                10'b0000000000, // [15:6] hartsel hi
                2'b00, // [5-4] - fixed zero
                1'b0, // [3] setresethaltreq
                1'b0, // [2] clrresethaltreq
                1'b0, // [1] ndmreset (1: To perform a system reset the debugger writes 1. 0: After writing 1 to reset the system, the debugger needs to write a 1 in order to stop the reset signal for the DM)
                //1'b1 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
                1'b0 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
            };

            // 17              16              15              14              13          12          11           10          9           8           7               6           5                   4                   3:0
            // allresumeack    anyresumeack    allnonexistent  anynonexistent  allunavail  anyunavail  allrunning   anyrunning  allhalted   anyhalted   authenticated   authbusy    hasresethaltreq     confstrptrvalid     version
            // 1               1               1               1               1           1           1            1           1           1           1               1           1                   1                   4

            // page 28, 3.14.1. Debug Module Status (dmstatus, at 0x11)
            baseline_register_dmstatus <= {

                7'b0000000, // fixed zero

                1'b0,   // [24] ndmresetpending
                1'b0,   // [23] stickyunavail
                1'b0,   // [22] impebreak

                2'b00,  // [20-21] fixed zero

                1'b0,   // [19] allhavereset
                1'b0,   // [18] anyhavereset

                1'b0,   // [17] allresumeack
                1'b0,   // [16] anyresumeack
                1'b0,   // [15] allnonexistent
                1'b0,   // [14] anynonexistent

                1'b0,   // [13] allunavail
                1'b0,   // [12] anyunavail
                1'b1,   // [11] allrunning
                1'b1,   // [10] anyrunning

                1'b0,   // [9] allhalted
                1'b0,   // [8] anyhalted
                1'b1,   // [7] authenticated    - The authentication check has passed. On components that don’t implement authentication, this bit must be preset as 1.
                1'b0,   // [6] authbusy

                1'b0,   // [5] hasresethaltreq
                1'b0,   // [4] confstrptrvalid  - address (pointer) of the configuration string
                4'b0010 // [3:0] version        - version of this DM (0010 is version 0.13). openocd only supports binary 2 (= version 0.13) and binary 3 (= version 1.0).

            };

            // 0x16
            baseline_register_abstractcs <= {
                3'b000,             // [31:29] fixed zero
                5'b00000,           // [28:24] progbufsize
                11'b00000000000,    // [23:13] fixed zero
                1'b0,               // [12] busy
                1'b0,               // [11] fixed zero
                3'b000,             // [10:8] cmd err
                4'b0000,            // [7:4] fixed zero
                4'b0010             // [3:0] datacount (how many data registers are available)
            };

            // 0x17
            baseline_register_command <= {
                8'b00000000,            // cmd type

                // control (24 bit)
                1'b0,                   // fixed 0
                3'b000,                 // aarsize
                1'b0,                   // aarpostincrement
                1'b0,                   // postexec
                1'b0,                   // transfer
                1'b0,                   // write
                16'b0000000000000000    // [15:0] regno
            };

            // 0x38, page 33
            baseline_register_sbcs <= {
                3'b001,         // [31:29] sbversion
                6'b000000,      // [28:23]
                1'b0,           // [22] sbbusyerror
                1'b0,           // [21] sbbusy
                1'b0,           // [20] sbreadonaddr
                3'b010,         // [19:17] sbaccess (2 == 32 bit)
                1'b0,           // [16] sbautoincrement
                1'b0,           // [15] sbreadondata
                3'b000,         // [14:12] sberror
                7'b0000000,     // [11:5] sbasize
                1'b0,           // [4] sbaccess128
                1'b0,           // [3] sbaccess64
                1'b0,           // [2] sbaccess32
                1'b0,           // [1] sbaccess16
                1'b0            // [0] sbaccess8
            };

            shift_reg_32 <= 0;
            shift_reg_42 <= 0;
            tdo_reg <= 0;

            current_state <= state_machine::TEST_LOGIC_RESET;

        end else begin

            case (current_state)

                state_machine::TEST_LOGIC_RESET: begin // 0

                    //$display("state_machine::TEST_LOGIC_RESET");

                    baseline_register_ir <= `IDCODE_IR_VALUE; // preselect the IDCODE baseline register on reset. This means shifting DR after a reset will produce the IDCODE of the target chip

                    baseline_register_idcode <= `CHIP_IDCODE; // 0001 0000 1110 0011 0001 1001 0001 0011

                    // 0x04
                    baseline_register_data0 <= {
                        32'b0
                        //32'hdeadbeef
                    };
                    // 0x05
                    baseline_register_data1 <= {
                        32'b0
                        //32'hcafebabe
                    };

                    // 0xAAC30021 == 1010101011 00 00 11 0000 00 000010 0001
                    baseline_register_dtmcontrol <= {
                        10'b1010101011, // [31:22]: Reserved.
                        2'b00, // [21:20]: ackbusy (Write-only): Writing 1 to this bit clears the busy condition after a failed request.
                        2'b00, // [19:18]: busy (Read-only): 1 if the DTM is currently busy with a previous request.
                        2'b11, // [17:16]: idle (Read/Write): Number of TCK cycles to wait in the Run-Test/Idle state.
                        4'b0000, // [15:12]: dmihardreset (Read/Write): Command to trigger a hard reset of the DMI.
                        2'b00, // dmireset (Read/Write): Resets the sticky error state (op != 0).
                        6'b001000, // abits (Read-only): Number of address bits in the DMI register.
                        4'b0001 // version
                    };

                    // 6.1.5 Debug Module Interface Access (dmi, at 0x11), page 65

                    // abits+33:34     33:2    1:0
                    // address         data    op
                    // abits           32      2

                    baseline_register_dmi <= {
                        8'b00000000, // address bits (abits). Has to be the size as specified in the dtmcontrol.abits field
                        32'b0, // data
                        2'b00 // op (00: nop (ignore data and address), 01: Read from address. (read), 10: Write data to address. (write), 11: Reserved)
                    };

                    //
                    // DMControl - https://riscv.org/wp-content/uploads/2024/12/riscv-debug-release.pdf, page 23
                    // DO NOT CONFUSE WITH DTMCONTROL!!!!!!!
                    //

                    // 31      30          29          28              27  26      25-16       15-6        5-4     3                   2                   1           0
                    // haltreq resumereq   hartreset   ackhavereset    0   hasel   hartsel lo  hartsel hi  00      setresethaltreq     clrresethaltreq     ndmreset    dmactive
                    // 1       1           1           1               1   1       10          10          2       1                   1                   1           1

                    // 0x10
                    baseline_register_dmcontrol <= {
                        1'b0, // [31] haltreq
                        1'b0, // [30] resumereq
                        1'b0, // [29] hartreset
                        1'b0, // [28] ackhavereset
                        1'b0, // [27] - fixed zero
                        1'b0, // [26] hasel - An implementation which does not implement the hart array mask register must tie this field to 0.
                        10'b0000000000, // [25:16] hartsel lo
                        10'b0000000000, // [15:6] hartsel hi
                        2'b00, // [5-4] - fixed zero
                        1'b0, // [3] setresethaltreq
                        1'b0, // [2] clrresethaltreq
                        1'b0, // [1] ndmreset (1: To perform a system reset the debugger writes 1. 0: After writing 1 to reset the system, the debugger needs to write a 0 in order to stop the reset signal for the DM)
                        1'b1 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
                        //1'b0 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
                    };

                    // 17              16              15              14              13          12          11           10          9           8           7               6           5                   4                   3:0
                    // allresumeack    anyresumeack    allnonexistent  anynonexistent  allunavail  anyunavail  allrunning   anyrunning  allhalted   anyhalted   authenticated   authbusy    hasresethaltreq     confstrptrvalid     version
                    // 1               1               1               1               1           1           1            1           1           1           1               1           1                   1                   4

                    // 0x11
                    baseline_register_dmstatus <= {

                        7'b0000000, // [31:25] fixed zero

                        1'b0,   // [24] ndmresetpending
                        1'b0,   // [23] stickyunavail
                        1'b0,   // [22] impebreak

                        2'b00,  // [20-21] fixed zero

                        1'b0,   // [19] allhavereset
                        1'b0,   // [18] anyhavereset

                        1'b0,   // [17] allresumeack
                        1'b0,   // [16] anyresumeack

                        1'b0,   // [15] allnonexistent
                        1'b0,   // [14] anynonexistent

                        1'b0,   // [13] allunavail
                        1'b0,   // [12] anyunavail

                        1'b1,   // [11] allrunning
                        1'b1,   // [10] anyrunning

                        1'b0,   // [9] allhalted
                        1'b0,   // [8] anyhalted

                        1'b1,   // [7] authenticated    - The authentication check has passed. On components that don’t implement authentication, this bit must be preset as 1.
                        1'b0,   // [6] authbusy

                        1'b0,   // [5] hasresethaltreq
                        1'b0,   // [4] confstrptrvalid  - address (pointer) of the configuration string
                        4'b0010 // [3:0] version        - version of this DM (0010 is version 0.13). openocd only supports binary 2 (= version 0.13) and binary 3 (= version 1.0).

                    };

                    // 0x16
                    baseline_register_abstractcs <= {
                        3'b000,             // [31:29] fixed zero
                        5'b00000,           // [28:24] progbufsize
                        11'b00000000000,    // [23:13] fixed zero
                        1'b0,               // [12] busy
                        1'b0,               // [11] fixed zero
                        3'b000,             // [10:8] cmd err
                        4'b0000,            // [7:4] fixed zero
                        4'b0010             // [3:0] datacount (how many data registers are available)
                    };

                    // 0x17
                    baseline_register_command <= {
                        8'b00000000, // [31:24] cmd type

                        // control (24 bit)
                        1'b0,   // fixed 0
                        3'b000, // aarsize
                        1'b0,   // aarpostincrement
                        1'b0,   // postexec
                        1'b0,   // transfer
                        1'b0,   // write
                        16'b0000000000000000 // regno
                    };

                    // 0x38, page 33
                    baseline_register_sbcs <= {
                        3'b001,         // [31:29] sbversion
                        6'b000000,      // [28:23]
                        1'b0,           // [22] sbbusyerror
                        1'b0,           // [21] sbbusy
                        1'b0,           // [20] sbreadonaddr
                        3'b010,         // [19:17] sbaccess (2 == 32 bit)
                        1'b0,           // [16] sbautoincrement
                        1'b0,           // [15] sbreadondata
                        3'b000,         // [14:12] sberror
                        7'b0000000,     // [11:5] sbasize
                        1'b0,           // [4] sbaccess128
                        1'b0,           // [3] sbaccess64
                        1'b0,           // [2] sbaccess32
                        1'b0,           // [1] sbaccess16
                        1'b0            // [0] sbaccess8
                    };

                    shift_reg_32 <= 0;
                    shift_reg_42 <= 0;
                    tdo_reg <= 0;

                    //$display("state_machine::TEST_LOGIC_RESET shift_reg_32:%x, baseline_register_ir:%x, baseline_register_idcode:%x", shift_reg_32, baseline_register_ir, baseline_register_idcode);

                    if (tms == 0) begin
                        current_state <= state_machine::RUN_TEST_IDLE;
                    end
                end

                state_machine::RUN_TEST_IDLE: begin // 1
                    //$display("state_machine::RUN_TEST_IDLE");
                    if (tms == 1) begin
                        current_state <= state_machine::SELECT_DR;
                    end
                end

                state_machine::SELECT_DR: begin // 2
                    //$display("state_machine::SELECT_DR");

                    if (tms == 0) begin

                        //
                        // This is one clock tick before, CAPTURE_DR
                        // This is the correct place to change the value of the baseline DR register
                        // before it is captured and immediately shifted out in the next clock cycle!
                        //

                        // when DTM.DMI register is captured, and the address is the DM.DMControl register, place the DM.DMControl bits into the DTM.DMI register
                        // The DTM.DMI register is used to read and write to the registers inside the DM from the JTAG TAP / RISC-V DTM.
                        case (baseline_register_ir)

                            `DMI_VALUE: begin
                                //$display("state_machine::SELECT_DR - DMI");

                                // switch over the address
                                // Format of the dmi register [aaaaaaaa][dddddddd.dddddddd.dddddddd.dddddddd][oo]
                                case (shift_reg_42[41:34])

                                    // data0
                                    8'h04: begin
                                        //$display("state_machine::SELECT_DR - DMI - Data0");
                                        baseline_register_dmi[33:2] <= baseline_register_data0;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end
                                    // data1
                                    8'h05: begin
                                        //$display("state_machine::SELECT_DR - DMI - Data1");
                                        baseline_register_dmi[33:2] <= baseline_register_data1;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // the dm.dtmcontrol (0x10) register is accessed
                                    8'h10: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.dtmcontrol");
                                        // mock value into the dm.dtmcontrol register

                                        // baseline_register_dmcontrol <= {
                                        //     1'b0, // [31] haltreq
                                        //     1'b0, // [30] resumereq
                                        //     1'b0, // [29] hartreset
                                        //     1'b0, // [28] ackhavereset
                                        //     1'b0, // [27] - fixed zero
                                        //     1'b0, // [26] hasel - An implementation which does not implement the hart array mask register must tie this field to 0.
                                        //     10'b0000000000, // [25:16] hartsel lo
                                        //     10'b0000000000, // [15:6] hartsel hi
                                        //     2'b00, // [5-4] - fixed zero
                                        //     1'b0, // [3] setresethaltreq
                                        //     1'b0, // [2] clrresethaltreq
                                        //     1'b0, // [1] ndmreset (1: To perform a system reset the debugger writes 1. 0: After writing 1 to reset the system, the debugger needs to write a 1 in order to stop the reset signal for the DM)
                                        //     1'b1 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
                                        // };

                                        baseline_register_dmi[33:2] <= baseline_register_dmcontrol;
                                        //baseline_register_dmi[2] <= 1'b1; // set the DM active otherwise openocd wont talk to us
                                        //baseline_register_dmi[3] <= 1'b0;

                                        baseline_register_dmi[28] <= 1'b0; // tie hartsel to 0 because this implementation does not support the hart array mask register

                                        // set all bits of hartsel to 0 as this DM only supports a single hart
                                        baseline_register_dmi[27:18] <= baseline_register_dmcontrol[27:18] & 10'b0000000001; // this line applies a AND-bitmask of 1 because the upper bits can never be selected as there is only a single hart
                                        baseline_register_dmi[17: 8] <= baseline_register_dmcontrol[17: 8] & 10'b0000000000; // this line applies a AND-bitmask of 0 because the upper bits can never be selected as there is only a single hart

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // the dm.dtmstatus (0x11) register is accessed
                                    8'h11: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.dtmstatus");
                                        baseline_register_dmi[33:2] <= baseline_register_dmstatus;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // the dm.hartinfo (0x12) register is accessed
                                    //
                                    // 3.12.3 Hart Info (hartinfo, at 0x12)
                                    // This register gives information about the hart currently selected by hartsel.
                                    // This register is optional. If it is not present it should read all-zero.
                                    8'h12: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.hartinfo");
                                        baseline_register_dmi[33:2] <= 32'b0;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // dm.abstractcs (0x16) register is accessed
                                    8'h16: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.abstractcs");
                                        baseline_register_dmi[33:2] <= baseline_register_abstractcs;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // the dm.command (0x17) register is accessed
                                    8'h17: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.command");
                                        baseline_register_dmi[33:2] <= baseline_register_command;



                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    // the dm.sbcs (0x38) register is accessed
                                    // 0x38 System Bus Access Control and Status (sbcs), page 32
                                    8'h38: begin
                                        //$display("state_machine::SELECT_DR - DMI - dm.sbcs");
                                        baseline_register_dmi[33:2] <= baseline_register_sbcs;

                                        baseline_register_dmi[1:0] <= 2'b00; // remove the command
                                    end

                                    default: begin
                                    end

                                endcase

                            end

                            default: begin
                            end

                        endcase

                        current_state <= state_machine::CAPTURE_DR;
                    end else begin
                        current_state <= state_machine::SELECT_IR; // 9
                    end
                end

                state_machine::CAPTURE_DR: begin // 3
                    //$display("state_machine::CAPTURE_DR");

                    //$display("state_machine::CAPTURE_DR baseline_register_ir:%x, baseline_register_idcode:%x", baseline_register_ir, baseline_register_idcode);

                    //
                    // look at code in baseline IR register
                    // copy baseline register identified by baseline IR content into shift register
                    //

                    // capture data into the correct shift register
                    case (baseline_register_ir)

                        // all ones (0xFFFFFFFF) is the identifier for the IDCODE register, which contains the unique ID of the chip so openocd can perform a comparison agains the code specified in the configuration file
                        // That way openocd is not used with the wrong configuration file on a targe-board
                        `IDCODE_IR_VALUE: begin
                            tdo_reg <= baseline_register_idcode[0]; // icode is captured into 32 bit shift register
                            shift_reg_32 <= { 1'h1, baseline_register_idcode[31:1] };
                            //$display("SET state_machine::CAPTURE_DR shift_reg_32:%x, baseline_register_ir:%x, baseline_register_idcode:%x", shift_reg_32, baseline_register_ir, baseline_register_idcode);
                        end

                        `DTMCONTROL_IR_VALUE: begin
                            //$display("SET state_machine::CAPTURE_DR DTMCONTROL baseline_register_dtmcontrol:%x", baseline_register_dtmcontrol);
                            tdo_reg <= baseline_register_dtmcontrol[0];
                            shift_reg_32 <= { tdi, baseline_register_dtmcontrol[31:1] };
                        end

                        `DMI_VALUE: begin
                            tdo_reg <= baseline_register_dmi[0];
                            shift_reg_42 <= { tdi, baseline_register_dmi[41:1] };
                        end

                        default: begin end

                    endcase

                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_DR;
                    end else begin
                        current_state <= state_machine::EXIT_1_DR;
                    end

                end

                state_machine::SHIFT_DR: begin // 4
                    //$display("state_machine::SHIFT_DR tdi:%x", tdi);

                    // select the correct shift register to shift
                    case (baseline_register_ir)

                        `IDCODE_IR_VALUE: begin // idcode selected
                            //$display("state_machine::SHIFT_DR %x", shift_reg_32);

                            // perform shift
                            tdo_reg <= shift_reg_32[0]; // icode is captured into 32 bit shift register
                            shift_reg_32 <= { 1'h1, shift_reg_32[31:1] };

                            //$display("state_machine::SHIFT_DR %x", shift_reg_32);
                        end

                        `DTMCONTROL_IR_VALUE: begin
                            //$display("state_machine::SHIFT_DR DTMCONTROL_IR_VALUE %x", shift_reg_32);

                            // perform shift
                            tdo_reg <= shift_reg_32[0];
                            shift_reg_32 <= { tdi, shift_reg_32[31:1] };
                        end

                        `DMI_VALUE: begin
                            // perform shift
                            tdo_reg <= shift_reg_42[0];
                            shift_reg_42 <= { tdi, shift_reg_42[41:1] };
                        end

                        default: begin
                            //$display("state_machine::SHIFT_DR UNKNOWN register %x", baseline_register_ir);
                        end
                    endcase

                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_1_DR;
                    end
                end

                state_machine::EXIT_1_DR: begin // 5
                    //$display("state_machine::EXIT_1_DR");
                    if (tms == 0) begin
                        current_state <= state_machine::PAUSE_DR;
                    end else begin
                        current_state <= state_machine::UPDATE_DR;
                    end
                end

                state_machine::PAUSE_DR: begin // 6
                    //$display("state_machine::PAUSE_DR");
                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_2_DR;
                    end
                end

                state_machine::EXIT_2_DR: begin // 7
                    //$display("state_machine::EXIT_2_DR");
                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_DR;
                    end else begin
                        current_state <= state_machine::UPDATE_DR;
                    end
                end

                state_machine::UPDATE_DR: begin // 8
                    //$display("state_machine::UPDATE_DR");

                    // TODO
                    // Special case for the ICODE register: https://developer.arm.com/documentation/ihi0031/a/The-JTAG-Debug-Port--JTAG-DP-/DR-scan-chain-and-DR-registers/The-JTAG-DP-Device-ID-Code-Register--IDCODE-
                    // Nothing happens at the Update-DR state. The shifted-in data is ignored.

                    // select the correct shift register to shift
                    case (baseline_register_ir)

                        // 0x01
                        `IDCODE_IR_VALUE: begin // idcode selected
                            //$display("state_machine::UPDATE_DR IGNORING Updates to IDCODE Baseline register!");
                        end

                        // 0x10
                        `DTMCONTROL_IR_VALUE: begin
                            // TODO: only the writeable parts should be update!
                            // Currently the entire baseline register is set to 0!

                            //$display("state_machine::UPDATE_DR DMCONTROL_IR_VALUE register!");
                            //baseline_register_dmcontrol <= shift_reg_32;
                        end

                        // 0x11, dtm.dmi register
                        `DMI_VALUE: begin

                            //$display("state_machine::UPDATE_DR dmi (0x11) register is accessed. shift_reg_42: %d", shift_reg_42);

                            // the value is only updated when the process terminates!!!!
                            // You cannot use the value baseline_register_dmi immediately
                            // do we even need to update this register?
                            baseline_register_dmi <= shift_reg_42;

                            // switch over the address
                            // Format of the dmi register [aaaaaaaa][dddddddd.dddddddd.dddddddd.dddddddd][oo]
                            case (shift_reg_42[41:34])

                                // data0
                                8'h04: begin
                                    //$display("state_machine::UPDATE_DR dmi dm.data0 (0x04) register is accessed");

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin
                                        baseline_register_data0 <= shift_reg_42[33:2];
                                    end
                                end
                                // data1
                                8'h05: begin
                                    //$display("state_machine::UPDATE_DR dmi dm.data1 (0x05) register is accessed");

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin
                                        baseline_register_data1 <= shift_reg_42[33:2];
                                    end
                                end

                                // the dm.dmcontrol (0x10) register is accessed
                                8'h10: begin

                                    //$display("state_machine::UPDATE_DR dmi dm.dmcontrol (0x10) register is accessed");

                                    // mock value into the dm.dtmcontrol register

                                    // baseline_register_dmcontrol <= {
                                    //     1'b0, // [31] haltreq
                                    //     1'b0, // [30] resumereq
                                    //     1'b0, // [29] hartreset
                                    //     1'b0, // [28] ackhavereset
                                    //     1'b0, // [27] - fixed zero
                                    //     1'b0, // [26] hasel
                                    //     10'b0000000000, // [25:16] hartsel lo
                                    //     10'b0000000000, // [15:6] hartsel hi
                                    //     2'b00, // [5-4] - fixed zero
                                    //     1'b0, // [3] setresethaltreq
                                    //     1'b0, // [2] clrresethaltreq
                                    //     1'b0, // [1] ndmreset (1: To perform a system reset the debugger writes 1. 0: After writing 1 to reset the system, the debugger needs to write a 1 in order to stop the reset signal for the DM)
                                    //     1'b1 // [0] dmactive (1: debug module functions normally. 0: makes the debug module perform a reset)
                                    // };

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin

                                        baseline_register_dmcontrol <= shift_reg_42[33:2];

                                        //baseline_register_dmi[2] <= 1'b1; // set the DM active otherwise openocd wont talk to us
                                        //baseline_register_dmi[28] <= 1'b0; // tie hartsel to 0 because this implementation does not support the hart array mask register

                                        // set all bits of hartsel to 0 except the first bit as this DM only supports a single hart
                                        //baseline_register_dmcontrol[27:18] <= shift_reg_42[27:18] & 10'b0000000001; // lo
                                        //baseline_register_dmcontrol[17: 8] <= shift_reg_42[17: 8] & 10'b0000000000; // hi

                                        // haltrequest
                                        // if openocd wants to halt the selected harts, change the dm.dmstatus register
                                        if (shift_reg_42[33] == 1'b1) begin // dm.dmcontrol[31] haltreq

                                            baseline_register_dmstatus <= {

                                                7'b0000000, // [31:25]
                                                1'b0,   // [24] ndmresetpending
                                                // ------------------------------
                                                1'b0,   // [23] stickyunavail
                                                1'b0,   // [22] impebreak

                                                2'b00,  // [21:20]

                                                1'b0,   // [19] allhavereset
                                                1'b0,   // [18] anyhavereset

                                                1'b0,   // [17] allresumeack
                                                1'b0,   // [16] anyresumeack
                                                // ------------------------------
                                                1'b0,   // [15] allnonexistent
                                                1'b0,   // [14] anynonexistent

                                                1'b0,   // [13] allunavail
                                                1'b0,   // [12] anyunavail

                                                1'b0,   // [11] allrunning
                                                1'b0,   // [10] anyrunning

                                                1'b1,   // [9] allhalted
                                                1'b1,   // [8] anyhalted
                                                // ------------------------------
                                                1'b1,   // [7] authenticated    - The authentication check has passed. On components that don’t implement authentication, this bit must be preset as 1.
                                                1'b0,   // [6] authbusy

                                                1'b0,   // [5] hasresethaltreq
                                                1'b0,   // [4] confstrptrvalid  - address (pointer) of the configuration string
                                                4'b0010 // [3:0] version        - version of this DM (0010 is version 0.13). openocd only supports binary 2 (= version 0.13) and binary 3 (= version 1.0).

                                            };
                                        end

                                        // if openocd wants to resume the selected harts, change the dm.dmstatus register
                                        if (shift_reg_42[32] == 1'b1) begin // dm.dmcontrol[30] resumereq

                                            baseline_register_dmstatus <= {

                                                7'b0000000,

                                                1'b0,   // [24] ndmresetpending
                                                1'b0,   // [23] stickyunavail
                                                1'b0,   // [22] impebreak

                                                2'b00,

                                                1'b0,   // [19] allhavereset
                                                1'b0,   // [18] anyhavereset

                                                1'b1,   // [17] allresumeack
                                                1'b1,   // [16] anyresumeack

                                                1'b0,   // [15] allnonexistent
                                                1'b0,   // [14] anynonexistent

                                                1'b0,   // [13] allunavail
                                                1'b0,   // [12] anyunavail

                                                1'b1,   // [11] allrunning - initially, harts are running
                                                1'b1,   // [10] anyrunning - initially, harts are running

                                                1'b0,   // [9] allhalted
                                                1'b0,   // [8] anyhalted

                                                1'b1,   // [7] authenticated    - The authentication check has passed. On components that don't implement authentication, this bit must be preset as 1.
                                                1'b0,   // [6] authbusy

                                                1'b0,   // [5] hasresethaltreq
                                                1'b0,   // [4] confstrptrvalid  - address (pointer) of the configuration string
                                                4'b0010 // [3:0] version        - version of this DM (0010 is version 0.13). openocd only supports binary 2 (= version 0.13) and binary 3 (= version 1.0).

                                            };
                                        end
                                    end
                                end

                                // the dm.dmstatus (0x11) register is accessed
                                8'h11: begin

                                    //$display("state_machine::UPDATE_DR dmi dm.dmstatus (0x11) register is accessed");

                                    // dm.dmstatus is a read only register!!!!

                                    // only when the operation is write, update the baseline DM register
                                    //if (shift_reg_42[1:0] == 2'b10) begin
                                    //    baseline_register_dmstatus <= shift_reg_42[33:2];
                                    //end

                                end

                                // dm.abstractcs (0x16) register is accessed (page 27)
                                8'h16: begin

                                    //$display("state_machine::UPDATE_DR dmi dm.abstractcs (0x16) register is accessed");

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin
                                        //baseline_register_abstractcs <= baseline_register_dmi[33:2];
                                        baseline_register_abstractcs <= shift_reg_42[33:2];
                                    end
                                end

                                // dm.command (0x17) register is accessed
                                8'h17: begin

                                    //$display("state_machine::UPDATE_DR dmi dm.command (0x17) register is accessed");

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin
                                        baseline_register_command <= shift_reg_42[33:2];
                                    end

                                    // otherwise openocd interprets the shifted out value as an error code and possibly flags the command as failed!
                                    baseline_register_dmi <= 32'b0;

                                    // check for "command type" (see page 12)
                                    case (shift_reg_42[33:26]) // 31    24 23    16 15     8 7      0
                                                               // 00000000.00000000.00000000.00000000
                                        // Command Type: "Access Register Command" (Read or Write) has the value 0
                                        8'b00000000: begin

                                            // Here, the register width (aarsize) is checked
                                            // This is required because openocd on purpose makes a test where it accesses a register with 64 bit widht without knowing XLEN.
                                            // If the chip is a 32 bit chip (XLEN=32), then it has to set dm.abstractcs.cmderr to 2 if a register is accessed with incorrect XLEN.

                                            // 2 is the code for 32 bit access. If the access is not 32 on this 32 bit CPU, then ---> error
                                            if (shift_reg_42[24:22] == 3'b100) begin // 128 bit

                                                //$display("dm.command (0x17), 128 bit --> error! bus error because of invalid width!");
                                                baseline_register_abstractcs[10:8] <= 3'b101; // 5 (bus): The abstract command failed due to a bus error (e.g. alignment, access size, or timeout)

                                            end else
                                            if (shift_reg_42[24:22] == 3'b011) begin  // 64 bit (page 19)

                                                //$display("dm.command (0x17), 64 bit --> error! bus error because of invalid width!");
                                                baseline_register_abstractcs[10:8] <= 3'b101; // 5 (bus): The abstract command failed due to a bus error (e.g. alignment, access size, or timeout)

                                            end else begin

                                                baseline_register_abstractcs[10:8] <= 3'b000; // No error

                                                baseline_register_data1 <= 32'hfaceb00c;

                                                // page 13, transfer
                                                //
                                                // 0: Don't do the operation specified by write.
                                                // 1: Do the operation specified by write.
                                                //
                                                // This bit can be used to just execute the Program Buffer without having to worry about placing valid values into aarsize or regno.
                                                if (shift_reg_42[19] == 1'b1) begin

                                                    //$display("dm.command (0x17), 32 bit, perform operation");

                                                    // check for reading or write register access
                                                    // register to data

                                                    // page 13,
                                                    // write
                                                    //
                                                    // When transfer is set:
                                                    // 0: Copy data from the specified register into arg0 portion of data.
                                                    // 1: Copy data from arg0 portion of data into the specified register.
                                                    //
                                                    // When transfer is NOT set:
                                                    // 0: do nothing
                                                    // 1: do nothing
                                                    if (shift_reg_42[18] == 1'b0) begin // case transfer == 1 && write == 0 (this is the register to data case)

                                                        // register to data

                                                        //$display("dm.command (0x17), 32 bit, perform operation, register to dataXYZ");

                                                        case (shift_reg_42[17:2])

                                                            // MISA CSR register
                                                            16'h0301: begin
                                                                //$display("dm.command (0x17), 32 bit, perform operation, register to dataXYZ, MISA (0x301) Register");
                                                                baseline_register_data0 <= 32'hbeebb00b;
                                                                baseline_register_data1 <= 32'hACE0FBA5;
                                                            end

                                                            default: begin
                                                                // TODO other registers
                                                                baseline_register_data0 <= 32'h0badc0de;
                                                                baseline_register_data1 <= 32'hBAADF00D;
                                                            end

                                                        endcase

                                                    end else begin
                                                        // TODO implement write (data to register)
                                                    end

                                                end
                                            end
                                        end

                                        default: begin
                                            // TODO: handle Quick Access and Access Memory Command (page 12)
                                        end

                                    endcase // command type

                                end

                                // dm.sbcs (0x38) register is accessed
                                8'h38: begin

                                    //$display("state_machine::UPDATE_DR dmi dm.sbcs (0x38) register is accessed");

                                    // only when the operation is write, update the baseline DM register
                                    if (shift_reg_42[1:0] == 2'b10) begin
                                        baseline_register_sbcs <= shift_reg_42[33:2];
                                    end
                                end

                                default: begin
                                    //$display("state_machine::UPDATE_DR unknown register");
                                end

                            endcase

                        end

                        default: begin end

                    endcase

                    if (tms == 0) begin
                        current_state <= state_machine::RUN_TEST_IDLE;
                    end else begin
                        current_state <= state_machine::SELECT_DR;
                    end
                end

                state_machine::SELECT_IR: begin // 9
                    //$display("state_machine::SELECT_IR");
                    if (tms == 0) begin
                        current_state <= state_machine::CAPTURE_IR;
                    end else begin
                        current_state <= state_machine::TEST_LOGIC_RESET;
                    end
                end

                state_machine::CAPTURE_IR: begin // 0x0A, 10
                    //$display("state_machine::CAPTURE_IR");

                    // transfer baseline IR into shift IR

                    // capture data into the correct shift register
                    case (baseline_register_ir)

                        // 0x01 is the identifier for the IDCODE register, which contains the unique ID of the chip so openocd can perform a comparison agains the code specified in the configuration file
                        // That way openocd is not used with the wrong configuration file on a targe-board
                        `IDCODE_IR_VALUE: begin
                            tdo_reg <= baseline_register_ir[0];
                            shift_reg_32 <= { 1'h1, baseline_register_ir[31:1] };
                            //$display("SET state_machine::CAPTURE_IR IDCODE shift_reg_32:%x, baseline_register_ir:%x, baseline_register_idcode:%x", shift_reg_32, baseline_register_ir, baseline_register_idcode);
                        end

                        `DTMCONTROL_IR_VALUE: begin
                            //$display("SET state_machine::CAPTURE_IR DTMCONTROL");
                            tdo_reg <= baseline_register_dtmcontrol[0];
                            shift_reg_32 <= { tdi, baseline_register_dtmcontrol[31:1] };
                        end

                        `DMI_VALUE: begin
                            //$display("SET state_machine::CAPTURE_IR DMI");
                            tdo_reg <= baseline_register_dmi[0];
                            shift_reg_42 <= { tdi, baseline_register_dmi[41:1] };
                        end

                        default: begin
                            //$display("SET state_machine::CAPTURE_IR UNKNOWN register:%x ", baseline_register_ir);
                        end

                    endcase

                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_IR;
                    end else begin
                        current_state <= state_machine::EXIT_1_IR;
                    end
                end

                state_machine::SHIFT_IR: begin // 0x0B, 11
                    //$display("state_machine::SHIFT_IR tdi:%x", tdi);

                    //$display("SET state_machine::SHIFT_IR tdi:%x, shift_reg_32:%x", tdi, shift_reg_32);

                    // perform shift
                    tdo_reg <= shift_reg_32[0];
                    shift_reg_32 <= { tdi, shift_reg_32[31:1] };

                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_1_IR;
                    end
                end

                state_machine::EXIT_1_IR: begin // 0x0C, 12
                    //$display("state_machine::EXIT_1_IR");

                    //$display("SET state_machine::EXIT_1_IR tdi:%x, shift_reg_32:%x", tdi, shift_reg_32);

                    if (tms == 0) begin
                        current_state <= state_machine::PAUSE_IR;
                    end else begin
                        current_state <= state_machine::UPDATE_IR;
                    end
                end

                state_machine::PAUSE_IR: begin // 0x0D, 13
                    //$display("state_machine::PAUSE_IR");
                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_2_IR;
                    end
                end

                state_machine::EXIT_2_IR: begin // 0x0E, 14
                    //$display("state_machine::EXIT_2_IR");
                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_IR;
                    end else begin
                        current_state <= state_machine::UPDATE_IR;
                    end
                end

                state_machine::UPDATE_IR: begin // 0x0F, 15
                    //$display("state_machine::UPDATE_IR");

                    baseline_register_ir <= shift_reg_32;

                    if (tms == 0) begin
                        current_state <= state_machine::RUN_TEST_IDLE;
                    end else begin
                        current_state <= state_machine::SELECT_DR;
                    end
                end

                default: begin end

            endcase

        end

    end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
