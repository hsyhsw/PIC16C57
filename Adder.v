`timescale 1ns/1ps

`include "CPUDef.v"

/**
 * Infers 8-bit adder with carry in
 */
module Adder(
		input[`ALU_DATA_WIDTH - 1:0] a,       //adder input a
		input[`ALU_DATA_WIDTH - 1:0] b,       //adder input b
		input subCmd,                         //0: add, 1: subtract
		output[`ALU_DATA_WIDTH - 1:0] result, //adder result
		output carry,                         //1 if carry occurred else, 0
		output digitCarry                     //1 if digit carry occurred else, 0
	);

	wire[3:0] ah; //a high
	wire[3:0] al; //a low
	assign {ah, al} = a;

	wire[3:0] bh; //b high
	wire[3:0] bl; //b low
	assign {bh, bl} = subCmd ? ~b : b;

	wire[3:0] rl; //result low
	wire[3:0] rh; //result high
	wire cl; //carry low
	wire ch; //carry high

	assign result = {rh, rl};

	assign {cl, rl} = al + bl + subCmd;
	assign {ch, rh} = ah + bh + cl;

	assign carry = ch;
	assign digitCarry = cl;

	//assign result = a + (subCmd ? ~b : b) + subCmd;

endmodule