`timescale 1ns/1ps

`include "CPUDef.v"

module PIC16C57(
		input clk,
		input rst,
		inout[`IO_A_WIDTH - 1:0] portAIO,
		inout[`IO_B_WIDTH - 1:0] portBIO,
		inout[`IO_C_WIDTH - 1:0] portCIO
	);

	reg[`PC_WIDTH - 1:0] PC;
	reg[`INST_WIDTH - 1:0] IR;
	reg[`DATA_WIDTH - 1:0] WR;
	reg skip;
	reg goto;

	wire byteDestF;
	assign byteDestF = IR[5];

	reg[`INST_WIDTH - 1:0] programMem[2047:0];

	initial begin
		$readmemh("program.mif", programMem);
		$display("Program loaded.");
	end

	// CU, CPU state and ALU function
	wire[`CU_FE_STATE_BITS - 1:0] fetchState;
	wire[`CU_EX_STATE_BITS - 1:0] executeState;
	wire[`ALU_FUNC_WIDTH - 1:0] aluFunc;
	CU cu(
		.clk(clk),
		.rst(rst),
		.instIn(IR),
		.fetchState(fetchState),
		.executeState(executeState),
		.aluFuncOut(aluFunc)
	);
	reg writeQ4Result;
	reg writeStatus;

	// IO ports binding
	reg[`IO_A_WIDTH - 1:0] trisAReg;
	reg[`IO_B_WIDTH - 1:0] trisBReg;
	reg[`IO_C_WIDTH - 1:0] trisCReg;
	wire[`IO_A_WIDTH - 1:0] portAOut;
	wire[`IO_B_WIDTH - 1:0] portBOut;
	wire[`IO_C_WIDTH - 1:0] portCOut;
	assign portAIO = {trisAReg[3] ? 1'bz : portAOut[3],
                      trisAReg[2] ? 1'bz : portAOut[2],
                      trisAReg[1] ? 1'bz : portAOut[1],
                      trisAReg[0] ? 1'bz : portAOut[0]};
	assign portBIO = {trisBReg[7] ? 1'bz : portBOut[7],
					  trisBReg[6] ? 1'bz : portBOut[6],
					  trisBReg[5] ? 1'bz : portBOut[5],
					  trisBReg[4] ? 1'bz : portBOut[4],
					  trisBReg[3] ? 1'bz : portBOut[3],
					  trisBReg[2] ? 1'bz : portBOut[2],
					  trisBReg[1] ? 1'bz : portBOut[1],
					  trisBReg[0] ? 1'bz : portBOut[0]};
	assign portCIO = {trisCReg[7] ? 1'bz : portCOut[7],
					  trisCReg[6] ? 1'bz : portCOut[6],
					  trisCReg[5] ? 1'bz : portCOut[5],
					  trisCReg[4] ? 1'bz : portCOut[4],
					  trisCReg[3] ? 1'bz : portCOut[3],
					  trisCReg[2] ? 1'bz : portCOut[2],
					  trisCReg[1] ? 1'bz : portCOut[1],
					  trisCReg[0] ? 1'bz : portCOut[0]};

	// Register file extra output
	wire[2:0] writeCommand;
	reg[`DATA_WIDTH - 1:0] fsrIndWriteData;
	reg[`DATA_WIDTH - 1:0] statusWriteData;
	wire[`DATA_WIDTH - 1:0] gprOut;
	wire[`DATA_WIDTH - 1:0] gprStatusOut;
	wire[`DATA_WIDTH - 1:0] gprFSROut;
	RegisterFile regFile(
		.clk(clk),
		.rst(rst),
		.writeCommand(writeCommand),
		.fileAddr(IR[4:0]),
		.writeDataIn(fsrIndWriteData),
		.statusIn(statusWriteData),
		.portAIn(portAIO),
		.portBIn(portBIO),
		.portCIn(portCIO),
		.pcIn(PC),
		.fsrOut(gprFSROut),
		.regfileOut(gprOut),
		.statusOut(gprStatusOut),
		.portAOut(portAOut),
		.portBOut(portBOut),
		.portCOut(portCOut)
	);

	assign writeCommand = {executeState == `EX_Q2_______FSR, // write FSR
	                       writeQ4Result, // write Q4 result to the register pointed to by FSR
	                       writeStatus};  // write status

	//Stack
	wire[1:0] stackCommand;
	wire[`PC_WIDTH - 1:0] stackIn;
	wire[`PC_WIDTH - 1:0] stackOut;
	assign stackCommand = executeState == `EX_Q4______CALL ? `STK_PUSH : (executeState == `EX_Q4_____RETLW ? `STK_POP : `STK_NOP);
	assign stackIn = PC;
	Stack stack(
		.clk(clk),
		.rst(rst),
		.commandIn(stackCommand),
		.in(stackIn),
		.topOut(stackOut)
	);

	// ALU
	wire[`ALU_STATUS_WIDTH - 1:0] aluStatusOut;
	wire[`ALU_DATA_WIDTH - 1:0] aluResultOut;
	ALU alu(
		.wIn(WR),          //working register in
		.fIn(gprOut),      //general purpose register in
		.lIn(IR[7:0]),     //literlal in
		.funcIn(aluFunc),  //alu function in
		.bitSel(IR[7:5]),  //bit selection in
		.cFlag(gprStatusOut[0]),  //carry flag in(for RRF, RLF instruction)
		.statusOut(aluStatusOut), //alu status out {zero, digit carry, carry}
		.resultOut(aluResultOut)  //alu result out
	);

	// writeQ4Result, fsrIndWriteData decision
	always @(byteDestF or executeState
		or IR or WR
		or aluResultOut) begin
		writeQ4Result = 0;
		fsrIndWriteData = 0;

		case (executeState)
			`EX_Q2_______FSR: begin
				fsrIndWriteData = {3'b000, IR[4:0]};
			end

			`EX_Q4______CLRF: begin
				writeQ4Result = 1;
				fsrIndWriteData = 0;
			end

			`EX_Q4_____MOVWF: begin
				writeQ4Result = 1;
				fsrIndWriteData = WR;
			end

			`EX_Q4_______BXF: begin
				writeQ4Result = 1;
				fsrIndWriteData = aluResultOut;
			end

			`EX_Q4_______FSZ,
			`EX_Q4______DECF,
			`EX_Q4_____SUBWF,
			`EX_Q4_____SWAPF,
			`EX_Q4___00_ELSE: begin
				if (byteDestF) begin
					writeQ4Result = 1;
					fsrIndWriteData = aluResultOut;
				end
			end
		endcase
	end

	// writeStatus, statusWriteData decision
	always @(executeState
		or gprStatusOut
		or aluStatusOut) begin
		writeStatus = 0;
		statusWriteData = 0;

		case (executeState)
			`EX_Q4______CLRF: begin
				writeStatus = 1;
				statusWriteData = {5'b0_0000, 1'b1, 1'b1, 2'b00};
			end

			`EX_Q4______CLRW: begin
				writeStatus = 1;
				statusWriteData = {gprStatusOut[7:3], 1'b1, 2'b00};
			end

			`EX_Q4______DECF,
			`EX_Q4_____SUBWF,
			`EX_Q4____ALUXLW,
			`EX_Q4___00_ELSE: begin
				writeStatus = 1;
				statusWriteData = {5'b0_0000, aluStatusOut};
			end
		endcase
	end

	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
			IR <= `I_NOP___12;
			WR <= 0;
			skip <= 0;
			goto <= 0;

			trisAReg <= `IO_A_WIDTH'hF;
			trisBReg <= `IO_B_WIDTH'hFF;
			trisCReg <= `IO_C_WIDTH'hFF;
		end
		else begin
			case (fetchState)
				`FE_Q1_____INCPC: begin
					if (!goto) begin
						PC <= PC + 1;
					end
				end

				`FE_Q2______IDLE,
				`FE_Q3______IDLE: begin
					// intentionally blank; do nothing
				end

				`FE_Q4_____FETCH: begin
					IR <= programMem[PC];
					//$display("IR <= Memory[0x%h] = 0x%h", PC, programMem[PC]);
				end

			endcase

			case (executeState)
				// Q1
				`EX_Q1_TEST_SKIP: begin
					if (skip | goto) begin
						skip <= 0;
						goto <= 0;
						IR <= `I_NOP___12;
					end
				end

				// Q2
				`EX_Q2_______FSR: begin
					// regFile[`ADDR_FSR] <= {gprFSROut[6:5], IR[4:0]};
					// intentionally blank; do nothing
				end

				`EX_Q2______ELSE: begin
					// intentionally blank; do nothing
				end

				// Q3
				`EX_Q3_______ALU: begin
					// intentionally blank; do nothing
				end

				// Q4
				`EX_Q4______CLRF: begin
					// intentionally blank; do nothing
					// writeRegFile(0);
					// regFile[`ADDR_STATUS] <= {5'b0_0000, 1'b1, 1'b1, 2'b00};
				end

				`EX_Q4______CLRW: begin
					WR <= 0;
					// regFile[`ADDR_STATUS] <= {gprStatusOut[7:3], 1'b1, 2'b00};
				end

				`EX_Q4______DECF: begin
					// if (byteDestF) begin
					// 	writeRegFile(aluResultOut);
					// end
					// else begin
					// 	WR <= aluResultOut;
					// end
					if (!byteDestF) begin
						WR <= aluResultOut;
					end

					// regFile[`ADDR_STATUS] <= {5'b0_0000, aluStatusOut};
				end

				`EX_Q4_____MOVWF: begin
					// writeRegFile(WR);
					// intentionally blank; do nothing
				end

				`EX_Q4_____SUBWF: begin
					// if (byteDestF) begin
					// 	writeRegFile(aluResultOut);
					// end
					// else begin
					// 	WR <= aluResultOut;
					// end
					if (!byteDestF) begin
						WR <= aluResultOut;
					end

					// regFile[`ADDR_STATUS] <= {5'b0_0000, aluStatusOut};
				end

				`EX_Q4____CLRWDT: begin
					// intentionally blank; do nothing
				end

				`EX_Q4____OPTION: begin
					// intentionally blank; do nothing
				end

				`EX_Q4_____SLEEP: begin
					// intentionally blank; do nothing
				end

				`EX_Q4______TRIS: begin
					case (IR[2:0])
						3'b101: begin //TRIS_A
							trisAReg <= WR;
						end

						3'b110: begin //TRIS_B
							trisBReg <= WR;
						end

						3'b111: begin //TRIS_C
							trisCReg <= WR;
						end
					endcase
				end

				`EX_Q4_______FSZ: begin
					// if (byteDestF) begin
					// 	writeRegFile(aluResultOut);
					// end
					// else begin
					// 	WR <= aluResultOut;
					// end
					if (!byteDestF) begin
						WR <= aluResultOut;
					end

					if (aluStatusOut[2]) begin // alu result is zero
						skip <= 1;
					end
				end

				`EX_Q4_____SWAPF: begin
					// if (byteDestF) begin
					// 	writeRegFile(aluResultOut);
					// end
					// else begin
					// 	WR <= aluResultOut;
					// end
					if (!byteDestF) begin
						WR <=aluResultOut;
					end
				end

				`EX_Q4______MOVF: begin
					WR <= gprOut;
				end

				`EX_Q4___00_ELSE: begin
					// if (byteDestF) begin
					// 	writeRegFile(aluResultOut);
					// end
					// else begin
					// 	WR <= aluResultOut;
					// end
					if (!byteDestF) begin
						WR <= aluResultOut;
					end

					// regFile[`ADDR_STATUS] <= {5'b0_0000, aluStatusOut};
				end

				`EX_Q4_______BXF: begin
					// writeRegFile(aluResultOut);
					// intentionally blank; do nothing
				end

				`EX_Q4_____BTFSX: begin
					if (IR[8]) begin // BTFSS
						if (gprOut[IR[7:5]]) begin // if set
							skip <= 1;
						end
					end
					else begin //BTFSC
						if (!gprOut[IR[7:5]]) begin // if clear
							skip <= 1;
						end
					end
				end

				`EX_Q4____ALUXLW: begin // ANDLW, IORLW, XORLW
					WR <= aluResultOut;
					// regFile[`ADDR_STATUS] <= {5'b0_0000, aluStatusOut};
				end

				`EX_Q4_____MOVLW: begin
					WR <= IR[7:0];
				end

				`EX_Q4______GOTO: begin
					PC <= {gprStatusOut[6:5], IR[8:0]};
					skip <= 1;
					goto <= 1;
				end

				`EX_Q4______CALL: begin
					PC <= {gprStatusOut[6:5], 1'b0, IR[7:0]};
					skip <= 1;
					goto <= 1;
				end

				`EX_Q4_____RETLW: begin
					WR <= IR[7:0];
					PC <= stackOut;
					skip <= 1;
					goto <= 1;
				end

				`EX_Q4______ELSE: begin
					// intentionally blank; do nothing
				end
			endcase

			// modify pcl instruction: same as CALL instruction
			if (writeCommand[1] && gprFSROut[4:0] == `ADDR_PCL) begin
				PC <= {gprStatusOut[6:5], 1'b0, IR[7:0]};
				skip <= 1;
			end
		end
	end
endmodule
