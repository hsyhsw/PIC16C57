`timescale 1ns/1ps

`include "CPUDef.v"

module ALU(
		input[`ALU_DATA_WIDTH - 1:0] wIn,          //working register in
		input[`ALU_DATA_WIDTH - 1:0] fIn,          //general purpose register in
		input[`ALU_DATA_WIDTH - 1:0] lIn,          //literlal in
		input[`ALU_FUNC_WIDTH - 1:0] funcIn,       //alu function in
		input[2:0] bitSel,                         //bit selection in
		input cFlag,                               //carry flag in(for RRF, RLF instruction)
		output[`ALU_STATUS_WIDTH - 1:0] statusOut, //alu status out {zero, digit carry, carry}
		output[`ALU_DATA_WIDTH - 1:0] resultOut    //alu result out
	);

	reg[`ALU_DATA_WIDTH - 1:0] adderA;
	reg[`ALU_DATA_WIDTH - 1:0] adderB;
	wire[`ALU_DATA_WIDTH - 1:0] adderOut;
	wire subCmd;
	wire adderCarry;
	wire adderDigitCarry;

	//subtraction when funcIn is ALU_SUBWF or ALU__DECF
	assign subCmd = (funcIn == `ALU_SUBWF) || (funcIn == `ALU__DECF);

	reg carry;
	reg[`ALU_DATA_WIDTH - 1:0] result;
	reg[`ALU_STATUS_WIDTH - 1:0] status;

	assign resultOut = result;
	assign statusOut = status;

	always @(funcIn or result or adderOut or carry or adderCarry or adderDigitCarry) begin
		//zero
		if (funcIn == `ALU_ADDWF || funcIn == `ALU_SUBWF) begin
			status = {(adderOut == 0), 1'b0, 1'b0};
		end
		else begin
			status = {(result == 0), 1'b0, 1'b0};
		end

		case (funcIn)
			`ALU_ADDWF,
			`ALU_SUBWF: begin
				status = status | {1'b0, adderDigitCarry, adderCarry};
			end

			`ALU___RLF,
			`ALU___RRF: begin
				status = status | {1'b0, 1'b0, carry};
			end
		endcase
	end

	always @(wIn or fIn or lIn or funcIn or cFlag or bitSel or adderOut) begin
		adderA = 0;
		adderB = 0;

		carry = 0;
		result = 0;

		case (funcIn)
			`ALU_ADDWF: begin //set carry, borrow
				adderA = fIn;
				adderB = wIn;
				result = adderOut;
			end

			`ALU_SUBWF: begin //set carry, borrow
				adderA = fIn;
				adderB = wIn;
				result = adderOut;
			end

			`ALU_ANDWF: begin
				result = wIn & fIn;
			end

			`ALU__COMF: begin
				result = ~fIn;
			end

			`ALU__DECF: begin
				adderA = fIn;
				adderB = 1;
				result = adderOut;
			end

			`ALU__INCF: begin
				adderA = fIn;
				adderB = 1;
				result = adderOut;
			end

			`ALU_IORWF: begin
				result = fIn | wIn;
			end

			`ALU___RLF: begin //rotate left through carry
				{carry, result} = {fIn[`ALU_DATA_WIDTH - 1:0], cFlag};
			end

			`ALU___RRF: begin //rotate right through carry
				{carry, result} = {fIn[0], cFlag, fIn[`ALU_DATA_WIDTH - 1:1]};
			end

			`ALU_SWAPF: begin
				result = {fIn[3:0], fIn[7:4]};
			end

			`ALU_XORWF: begin
				result = fIn ^ wIn;
			end

			`ALU___BCF: begin //clear bitsel_th bit of GPR[f]
				result = fIn & ~(8'h01 << bitSel);
			end

			`ALU___BSF: begin //set bitsel_th bit of GPR[f]
				result = fIn | (8'h01 << bitSel);
			end

			`ALU_ANDLW: begin
				result = wIn & lIn;
			end

			`ALU_IORLW: begin
				result = wIn | lIn;
			end

			`ALU_XORLW: begin
				result = wIn ^ lIn;
			end

			`ALU__IDLE: begin
				result = 8'hED;
			end

			default: begin
				result = 8'hDE;
			end

		endcase
	end

	//two 5-bit adder with carry in inferred here.
	Adder adder(
		.a(adderA),
		.b(adderB),
		.subCmd(subCmd),
		.result(adderOut),
		.carry(adderCarry),
		.digitCarry(adderDigitCarry)
	);

endmodule
