/* verilator lint_off UNUSEDSIGNAL */

module tap (

    input   logic tck, // JTAG clock
    input   logic tdi,
    output  logic tdo,
    input   logic tms,
    input   logic trst

);

    state_machine::states_t current_state;

    logic [31:0] shift_reg_32;

    logic [31:0] baseline_register_idcode;
    logic [31:0] baseline_register_ir;

    initial begin
        $display("Hello World");
        $finish;
    end

    always_ff @(posedge tck)
    begin
        tdo <= 0;
    end

    always_ff @(posedge tck)
    begin

        if (trst == 1) begin

            baseline_register_idcode <= 32'h10e31913; // 0001 0000 1110 0011 0001 1001 0001 0011
            baseline_register_ir <= 32'hFFFFFFFF; // preselect the IDCODE baseline register on reset. This means shifting DR after a reset will produce the IDCODE of the target chip

            shift_reg_32 <= 32'h00;

            current_state <= state_machine::TEST_LOGIC_RESET;

        end else begin

            case (current_state)

                state_machine::TEST_LOGIC_RESET: begin // 0
                    if (tms == 0) begin
                        current_state <= state_machine::RUN_TEST_IDLE;
                    end
                end

                state_machine::RUN_TEST_IDLE: begin // 1
                    if (tms == 1) begin
                        current_state <= state_machine::SELECT_DR;
                    end
                end

                state_machine::SELECT_DR: begin // 2
                    if (tms == 0) begin
                        current_state <= state_machine::CAPTURE_DR;
                    end else begin
                        current_state <= state_machine::SELECT_IR; // 9
                    end
                end

                state_machine::CAPTURE_DR: begin // 3

                    // look at code in basline IR register
                    // copy baseline register identified by baseline IR content into shift register

                    // capture data into the correct shift register
                    case (baseline_register_ir)

                        // all ones is the identifier for the IDCODE register, which contains the unique ID of the chip so openocd can perform a comparison agains the code specified in the configuration file
                        // That way openocd is not used with the wrong configuration file on a targe-board
                        32'hFFFFFFFF: begin
                            shift_reg_32 <= baseline_register_idcode;
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

                    // select the correct shift register to shift
                    case (baseline_register_ir)

                        32'hFFFFFFFF: begin // idcode selected
                            tdo <= shift_reg_32[0]; // icode is captured into 32 bit shift register
                            shift_reg_32 <= { tdi, shift_reg_32[31:1] };
                        end

                        default: begin end
                    endcase

                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_1_DR;
                    end
                end

                state_machine::EXIT_1_DR: begin // 5
                    if (tms == 0) begin
                        current_state <= state_machine::PAUSE_DR;
                    end else begin
                        current_state <= state_machine::UPDATE_DR;
                    end
                end

                state_machine::PAUSE_DR: begin // 6
                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_2_DR;
                    end
                end

                state_machine::EXIT_2_DR: begin // 7
                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_DR;
                    end else begin
                        current_state <= state_machine::UPDATE_DR;
                    end
                end

                state_machine::UPDATE_DR: begin // 8
                    if (tms == 0) begin
                        current_state <= state_machine::RUN_TEST_IDLE;
                    end else begin
                        current_state <= state_machine::SELECT_DR;
                    end
                end

                state_machine::SELECT_IR: begin // 9
                    if (tms == 0) begin
                        current_state <= state_machine::CAPTURE_IR;
                    end else begin
                        current_state <= state_machine::TEST_LOGIC_RESET;
                    end
                end

                state_machine::CAPTURE_IR: begin // 10
                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_IR;
                    end else begin
                        current_state <= state_machine::EXIT_1_IR;
                    end
                end

                state_machine::SHIFT_IR: begin // 11



                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_1_IR;
                    end
                end

                state_machine::EXIT_1_IR: begin // 12
                    if (tms == 0) begin
                        current_state <= state_machine::PAUSE_IR;
                    end else begin
                        current_state <= state_machine::UPDATE_IR;
                    end
                end

                state_machine::PAUSE_IR: begin // 13
                    if (tms == 1) begin
                        current_state <= state_machine::EXIT_2_IR;
                    end
                end

                state_machine::EXIT_2_IR: begin // 14
                    if (tms == 0) begin
                        current_state <= state_machine::SHIFT_IR;
                    end else begin
                        current_state <= state_machine::UPDATE_IR;
                    end
                end

                state_machine::UPDATE_IR: begin // 15
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

endmodule;

/* verilator lint_on UNUSEDSIGNAL */
