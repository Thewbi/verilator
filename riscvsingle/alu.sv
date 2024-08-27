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
        input clk,
        input reset,

        input  common::operation_t  op_in,
        input  [WIDTH-1:0]  a_in,
        input  [WIDTH-1:0]  b_in,
        input               in_valid,

        output logic [WIDTH-1:0]  out,
        output logic              out_valid,
		
	output logic N, // negative
	output logic Z, // zero
	output logic C, // carry

	output logic V_1,  // overflow
 	output logic V_2,
	output logic V_3,
	output logic V  // overflow
); 

        common::operation_t  	    op_in_r;
        logic  [WIDTH-1:0]  a_in_r;
        logic  [WIDTH-1:0]  b_in_r;
        logic               in_valid_r;
        logic  [WIDTH-1:0]  result;

	//logic V_1;
	//logic V_2;
	//logic V_3;

        // register all inputs
        always_ff @ (posedge clk, posedge reset) begin
                if (reset) begin
                        op_in_r     <= common::nop;
                        a_in_r      <= '0;
                        b_in_r      <= '0;
                        in_valid_r  <= '0;
                end else begin
                        op_in_r    <= op_in;
                        a_in_r     <= a_in;
                        b_in_r     <= b_in;
                        in_valid_r <= in_valid;
                end
        end

        // compute the result
        always_comb begin
                result = '0;
                if (in_valid_r) begin
                        case (op_in_r)
                                common::add: {C, result} = a_in_r + b_in_r; 
                                common::sub: {C, result} = a_in_r + (~b_in_r + 1'b1);
                                default: result = '0;
                        endcase
                end
				
		N = result[WIDTH-1];
		Z = result == 0;
				
		V_1 = (op_in_r == common::add) || (op_in_r == common::sub);
		V_2 = a_in_r[WIDTH-1] ^ result[WIDTH-1];
		V_3 = ((a_in_r[WIDTH-1] == b_in_r[WIDTH-1]) && (op_in_r == common::add)) || ((a_in_r[WIDTH-1] != b_in_r[WIDTH-1]) && (op_in_r == common::sub));

		V = V_1 && V_2 && V_3;
        end

        // register outputs
        always_ff @ (posedge clk, posedge reset) begin
                if (reset) begin
                        out       <= '0;
                        out_valid <= '0;
                end else begin
                        out       <= result;
                        out_valid <= in_valid_r;
                end
        end

endmodule
