// from: https://itsembedded.com/dhd/verilator_1/

///****** alu.sv ******/
//typedef enum logic [1:0] {
//     add     = 2'h0,
//     sub     = 2'h1,
//     nop     = 2'h2
//} operation_t /*verilator public*/;

import common::operation_t;

module alu #(
        parameter WIDTH = 32
) (
//        input clk,
//        input reset,

//        input  common::operation_t  op_in,

        
        input  [WIDTH-1:0]              a_in,
        input  [WIDTH-1:0]              b_in,
        input  logic [2:0]              ALUControl,
        output logic [WIDTH-1:0] 	ALUResult,
        output logic Z // zero

//        input               in_valid,

//        output logic [WIDTH-1:0]  out,
//        output logic              out_valid,
		
//	output logic N, // negative
//	output logic Z, // zero
//	output logic C, // carry

//	output logic V_1,  // overflow
 //	output logic V_2,
//	output logic V_3,
//	output logic V  // overflow
); 

//        common::operation_t  	    op_in_r;
//        logic  [WIDTH-1:0]  a_in_r;
//        logic  [WIDTH-1:0]  b_in_r;
//        logic               in_valid_r;
//        logic  [WIDTH-1:0]  result;

	//logic V_1;
	//logic V_2;
	//logic V_3;

        logic C; // carry

        // register all inputs
        // always_ff @ (posedge clk, posedge reset) begin
        //         if (reset) begin
        //                 op_in_r     <= common::nop;
        //                 a_in_r      <= '0;
        //                 b_in_r      <= '0;
        //                 in_valid_r  <= '0;
        //         end else begin
        //                 op_in_r    <= op_in;
        //                 a_in_r     <= a_in;
        //                 b_in_r     <= b_in;
        //                 in_valid_r <= in_valid;
        //         end
        // end

        // compute the result
        always_comb begin
                ALUResult = '0;
                //if (in_valid_r) begin
                        case (ALUControl)

                                // add (see alu_decoder.sv)
                                //3'b000: {C, ALUResult} = a_in + b_in; // this works in questa
                                3'b000: ALUResult = a_in + b_in;

                                // sub
                                //3'b001: {C, ALUResult} = a_in + (~b_in + 1'b1); // this works in questa
                                3'b001: ALUResult = a_in + (~b_in + 1'b1);

                                // and, andi
                                3'b010: ALUResult = a_in & b_in;

                                // or, ori
                                3'b011: ALUResult = a_in | b_in;

                                // slt, slti
                                // SLTI (set less than immediate) places the value 1 in register rd if 
                                // register rs1 is less than the signextended immediate when both are treated 
                                // as signed numbers, else 0 is written to rd.
                                3'b101: ALUResult = a_in < b_in ? 1 : 0;

                                default: ALUResult = '0;

                        endcase
                //end
				
		//N = result[WIDTH-1];
		Z = ALUResult == 0;
				
		//V_1 = (op_in_r == common::add) || (op_in_r == common::sub);
		//V_2 = a_in_r[WIDTH-1] ^ result[WIDTH-1];
		//V_3 = ((a_in_r[WIDTH-1] == b_in_r[WIDTH-1]) && (op_in_r == common::add)) || ((a_in_r[WIDTH-1] != b_in_r[WIDTH-1]) && (op_in_r == common::sub));

		//V = V_1 && V_2 && V_3;
        end

        // // register outputs
        // always_ff @ (posedge clk, posedge reset) begin
        //         if (reset) begin
        //                 out       <= '0;
        //                 out_valid <= '0;
        //         end else begin
        //                 out       <= result;
        //                 out_valid <= in_valid_r;
        //         end
        // end

endmodule
