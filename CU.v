`timescale 1ns/1ps

`include "CPUDef.v"

module CU(
		input clk,
		input rst,
		input[`INST_WIDTH - 1:0] instIn,
		output[`CU_FE_STATE_BITS - 1:0] fetchState,
		output[`CU_EX_STATE_BITS - 1:0] executeState,
		output[`ALU_FUNC_WIDTH - 1:0] aluFuncOut
	);

	reg[`CU_FE_STATE_BITS - 1:0] currentFetchState;
	reg[`CU_EX_STATE_BITS - 1:0] currentExecuteState;
	reg[`CU_FE_STATE_BITS - 1:0] nextFetchState;
	reg[`CU_EX_STATE_BITS - 1:0] nextExecuteState;
	assign fetchState = currentFetchState;
	assign executeState = currentExecuteState;


	reg[`ALU_FUNC_WIDTH - 1:0] aluFunc;
	reg[`ALU_FUNC_WIDTH - 1:0] aluFuncRetain;
	assign aluFuncOut = aluFuncRetain;

	//execute, fetch state transition
	always @(posedge clk) begin
		if (rst) begin
			currentExecuteState <= `EX_Q3_______ALU;
			currentFetchState <= `FE_Q3______IDLE;
		end
		else begin
			currentExecuteState <= nextExecuteState;
			currentFetchState <= nextFetchState;
		end
	end

	//ALU function loading
	always @(posedge clk) begin
		if (rst) begin
			aluFuncRetain <= `ALU__IDLE;
		end
		else if (nextExecuteState == `EX_Q3_______ALU) begin
			aluFuncRetain <= aluFunc;
		end
	end

	//next execute state logic
	always @(currentExecuteState or instIn) begin
		aluFunc = `ALU__IDLE;
		case (currentExecuteState)
			/**
			 * Q1
			 */
			`EX_Q1_TEST_SKIP: begin
				// if (instIn[11:6] == `I_SUBWF__6 || instIn[11:6] == `I_DECF___6
				// 	|| instIn[11:5] == `I_CLRF___7 || instIn[11:5] == `I_MOVWF__7) begin //SUBWF, DECF, CLRF, MOVWF
				// 	nextExecuteState = `EX_Q2_______FSR;
				// end
				// else if (instIn[11:10] == 2'b00 || instIn[11:10] == 2'b01) begin
				// 	nextExecuteState = `EX_Q2_______FSR;
				// end
				// else begin
				// 	nextExecuteState = `EX_Q2______ELSE;
				// end
				nextExecuteState = `EX_Q2______ELSE;
			end

			/**
			 * Q2
			 */
			`EX_Q2______ELSE,
			`EX_Q2_______FSR: begin
				nextExecuteState = `EX_Q3_______ALU;

				if (instIn[11:8] == 4'b0000) begin
					if (instIn[11:6] == `I_DECF___6) begin
						aluFunc = `ALU__DECF;
					end
					else if (instIn[11:6] == `I_SUBWF__6) begin
						aluFunc = `ALU_SUBWF;
					end
					else begin
						aluFunc = `ALU__IDLE;
					end
				end
				else if (instIn[11:10] == 2'b00) begin
					case (instIn[11:6])
						`I_ADDWF__6: begin
							aluFunc = `ALU_ADDWF;
						end

						`I_ANDWF__6: begin
							aluFunc = `ALU_ANDWF;
						end

						`I_COMF___6: begin
							aluFunc = `ALU__COMF;
						end

						`I_DECF___6: begin
							aluFunc = `ALU__DECF;
						end

						`I_DECFSZ_6: begin
							aluFunc = `ALU__DECF;
						end

						`I_INCF___6: begin
							aluFunc = `ALU__INCF;
						end

						`I_INCFSZ_6: begin
							aluFunc = `ALU__INCF;
						end

						`I_IORWF__6: begin
							aluFunc = `ALU_IORWF;
						end

						`I_RLF____6: begin
							aluFunc = `ALU___RLF;
						end

						`I_RRF____6: begin
							aluFunc = `ALU___RRF;
						end

						`I_SWAPF__6: begin
							aluFunc = `ALU_SWAPF;
						end

						`I_XORWF__6: begin
							aluFunc = `ALU_XORWF;
						end
					endcase
				end
				else if (instIn[11:10] == 2'b01) begin
					if (instIn[11:8] == `I_BCF____4) begin
						aluFunc = `ALU___BCF;
					end
					else if (instIn[11:8] == `I_BCF____4) begin
						aluFunc = `ALU___BSF;
					end
				end
				else begin
					if (instIn[11:8] == `I_ANDLW__4) begin
						aluFunc = `ALU_ANDLW;
					end
					else if (instIn[11:8] == `I_IORLW__4) begin
						aluFunc = `ALU_IORLW;
					end
					else if (instIn[11:8] == `I_XORLW__4) begin
						aluFunc = `ALU_XORLW;
					end
				end
			end

			/**
			 * Q3
			 */
			`EX_Q3_______ALU: begin
				if (instIn[11:8] == 4'b0000) begin
					casex (instIn)
						{`I_CLRF___7,    5'bx_xxxx}: begin
							nextExecuteState = `EX_Q4______CLRF;
						end

						{`I_CLRW__12              }: begin
							nextExecuteState = `EX_Q4______CLRW;
						end

						{`I_DECF___6,   6'bxx_xxxx}: begin
							nextExecuteState = `EX_Q4______DECF;
						end

						{`I_MOVWF__7,    5'bx_xxxx}: begin
							nextExecuteState = `EX_Q4_____MOVWF;
						end

						{`I_SUBWF__6,   6'bxx_xxxx}: begin
							nextExecuteState = `EX_Q4_____SUBWF;
						end

						{`I_CLRWDT_4, 8'bxxxx_xxxx}: begin
							nextExecuteState = `EX_Q4____CLRWDT;
						end

						{`I_OPTION_4, 8'bxxxx_xxxx}: begin
							nextExecuteState = `EX_Q4____OPTION;
						end

						{`I_SLEEP__4, 8'bxxxx_xxxx}: begin
							nextExecuteState = `EX_Q4_____SLEEP;
						end

						{`I_TRIS___4, 8'bxxxx_xxxx}: begin
							nextExecuteState = `EX_Q4______TRIS;
						end

						default: begin
							nextExecuteState = `EX_Q4______ELSE;
						end
					endcase
				end //end of 0000_xxxx_xxxx

				else if (instIn[11:10] == 2'b00) begin
					case (instIn[11:6])
						`I_INCFSZ_6,
						`I_DECFSZ_6: begin
							nextExecuteState = `EX_Q4_______FSZ;
						end

						`I_SWAPF__6: begin
							nextExecuteState = `EX_Q4_____SWAPF;
						end

						`I_MOVF___6: begin
							nextExecuteState = `EX_Q4______MOVF;
						end


						default: begin
							nextExecuteState = `EX_Q4___00_ELSE;
						end
					endcase
				end //end of 00xx_xxxx_xxxx

				else if (instIn[11:10] == 2'b01) begin
					case (instIn[11:8])
						`I_BCF____4,
						`I_BSF____4: begin
							nextExecuteState = `EX_Q4_______BXF;
						end

						`I_BTFSC__4,
						`I_BTFSS__4: begin
							nextExecuteState = `EX_Q4_____BTFSX;
						end

						default: begin
							nextExecuteState = `EX_Q4______ELSE;
						end
					endcase
				end //end of 01xx_xxxx_xxxx

				// TODO: handle unknown(xxx...) instruction
				else begin
					casex (instIn[11:8])
						{`I_ANDLW__4      },
						{`I_IORLW__4      },
						{`I_XORLW__4      }: begin
							nextExecuteState = `EX_Q4____ALUXLW;
						end

						{`I_MOVLW__4      }: begin
							nextExecuteState = `EX_Q4_____MOVLW;
						end

						{`I_GOTO___3, 1'bx}: begin
							nextExecuteState = `EX_Q4______GOTO;
						end

						{`I_CALL___4      }: begin
							nextExecuteState = `EX_Q4______CALL;
						end

						{`I_RETLW__4      }: begin
							nextExecuteState = `EX_Q4_____RETLW;
						end

						default: begin
							nextExecuteState = `EX_Q4______ELSE;
						end
					endcase
				end //end of else
			end

			/**
			 * Q4
			 */
			`EX_Q4______CLRF,
			`EX_Q4______CLRW,
			`EX_Q4______DECF,
			`EX_Q4_____MOVWF,
			`EX_Q4______MOVF,
			`EX_Q4_____SUBWF,
			`EX_Q4____CLRWDT,
			`EX_Q4____OPTION,
			`EX_Q4_____SLEEP,
			`EX_Q4______TRIS,
			`EX_Q4_______FSZ,
			`EX_Q4_____SWAPF,
			`EX_Q4___00_ELSE,
			`EX_Q4_______BXF,
			`EX_Q4_____BTFSX,
			`EX_Q4____ALUXLW,
			`EX_Q4_____MOVLW,
			`EX_Q4______GOTO,
			`EX_Q4______CALL,
			`EX_Q4_____RETLW,
			`EX_Q4______ELSE: begin
				nextExecuteState = `EX_Q1_TEST_SKIP;
			end

			default: begin //should not be happened!!!
				$display("Should not be happened! currentExecuteState: 0x%h", currentExecuteState);
				nextExecuteState = `EX_Q1_TEST_SKIP;
			end

		endcase
	end

	//next fetch state logic
	always @(currentFetchState) begin
		case (currentFetchState)
			`FE_Q1_____INCPC: begin
				nextFetchState = `FE_Q2______IDLE;
			end

			`FE_Q2______IDLE: begin
				nextFetchState = `FE_Q3______IDLE;
			end

			`FE_Q3______IDLE: begin
				nextFetchState = `FE_Q4_____FETCH;
			end

			`FE_Q4_____FETCH: begin
				nextFetchState = `FE_Q1_____INCPC;
			end
		endcase
	end

endmodule
