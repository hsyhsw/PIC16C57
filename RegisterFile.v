`timescale 1ns/1ps

`include "CPUDef.v"

module RegisterFile(
		input clk,
		input rst,
		input[2:0] writeCommand,
		input[4:0] fileAddr,
		input[`DATA_WIDTH - 1:0] writeDataIn,
		input[`DATA_WIDTH - 1:0] statusIn,
		input[`IO_A_WIDTH - 1:0] portAIn,
		input[`IO_B_WIDTH - 1:0] portBIn,
		input[`IO_C_WIDTH - 1:0] portCIn,
		input[`PC_WIDTH - 1:0] pcIn,
		output[`DATA_WIDTH - 1:0] fsrOut,
		output[`DATA_WIDTH - 1:0] regfileOut,
		output[`DATA_WIDTH - 1:0] statusOut,
		output[`IO_A_WIDTH - 1:0] portAOut,
		output[`IO_B_WIDTH - 1:0] portBOut,
		output[`IO_C_WIDTH - 1:0] portCOut
	);

	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] status;
	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] FSReg;
	(* KEEP = "TRUE" *) reg[`IO_A_WIDTH - 1:0] portA;
	(* KEEP = "TRUE" *) reg[`IO_B_WIDTH - 1:0] portB;
	(* KEEP = "TRUE" *) reg[`IO_C_WIDTH - 1:0] portC;
	reg[`DATA_WIDTH - 1:0] indirect; // not real register
	reg[`DATA_WIDTH - 1:0] direct; // not real register

	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] GPR00[15:8];
	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] GPR01[15:0];
	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] GPR11[15:0];
	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] GPR21[15:0];
	(* KEEP = "TRUE" *) reg[`DATA_WIDTH - 1:0] GPR31[15:0];

	assign fsrOut = FSReg;
	assign regfileOut = (fileAddr == `ADDR_INDF) ? indirect : direct;
	assign statusOut = status;
	assign portAOut = portA;
	assign portBOut = portB;
	assign portCOut = portC;

	// fsr indirect read (a.k.a. INDF register)
	always @(pcIn or status or FSReg
		or portAIn or portBIn or portCIn
		or GPR00[FSReg[3:0]]
		or GPR01[FSReg[3:0]]
		or GPR11[FSReg[3:0]]
		or GPR21[FSReg[3:0]]
		or GPR31[FSReg[3:0]]) begin

		case (FSReg[4:0])
			`ADDR_INDF: begin
				indirect = 0;
			end

			`ADDR_TMR0: begin
				indirect = 0;
			end

			`ADDR_PCL: begin
				indirect = pcIn[7:0];
			end

			`ADDR_STATUS: begin
				indirect = status;
			end

			`ADDR_FSR: begin
				indirect = FSReg;
			end

			`ADDR_PORTA: begin
				indirect = {4'b0000, portAIn};
			end

			`ADDR_PORTB: begin
				indirect = portBIn;
			end

			`ADDR_PORTC: begin
				indirect = portCIn;
			end

			// GPR00
			5'h08,
			5'h09,
			5'h0A,
			5'h0B,
			5'h0C,
			5'h0D,
			5'h0E,
			5'h0F: begin
				indirect = GPR00[FSReg[3:0]];
			end

			// GPRX1
			5'h10,
			5'h11,
			5'h12,
			5'h13,
			5'h14,
			5'h15,
			5'h16,
			5'h17,
			5'h18,
			5'h19,
			5'h1A,
			5'h1B,
			5'h1C,
			5'h1D,
			5'h1E,
			5'h1F: begin
				case (FSReg[6:5])
					2'b00: begin
						indirect = GPR01[FSReg[3:0]];
					end

					2'b01: begin
						indirect = GPR11[FSReg[3:0]];
					end

					2'b10: begin
						indirect = GPR21[FSReg[3:0]];
					end

					2'b11: begin
						indirect = GPR31[FSReg[3:0]];
					end
				endcase
			end
		endcase
	end

	// direct read
	always @(pcIn or fileAddr or status or FSReg
		or portAIn or portBIn or portCIn
		or GPR00[fileAddr]
		or GPR01[fileAddr[3:0]]
		or GPR11[fileAddr[3:0]]
		or GPR21[fileAddr[3:0]]
		or GPR31[fileAddr[3:0]]) begin
		case (fileAddr)
			`ADDR_INDF: begin
				direct = `DATA_WIDTH'bx;
			end

			`ADDR_TMR0: begin
				direct = `DATA_WIDTH'bx;
			end

			`ADDR_PCL: begin
				direct = pcIn[7:0];
			end

			`ADDR_STATUS: begin
				direct = status;
			end

			`ADDR_FSR: begin
				direct = FSReg;
			end

			`ADDR_PORTA: begin
				direct = {4'b0000, portAIn};
			end

			`ADDR_PORTB: begin
				direct = portBIn;
			end

			`ADDR_PORTC: begin
				direct = portCIn;
			end

			// GPR00
			5'h08,
			5'h09,
			5'h0A,
			5'h0B,
			5'h0C,
			5'h0D,
			5'h0E,
			5'h0F: begin
				direct = GPR00[fileAddr];
			end

			// GPRX1
			5'h10,
			5'h11,
			5'h12,
			5'h13,
			5'h14,
			5'h15,
			5'h16,
			5'h17,
			5'h18,
			5'h19,
			5'h1A,
			5'h1B,
			5'h1C,
			5'h1D,
			5'h1E,
			5'h1F: begin
				case (FSReg[6:5])
					2'b00: begin
						direct = GPR01[fileAddr[3:0]];
					end

					2'b01: begin
						direct = GPR11[fileAddr[3:0]];
					end

					2'b10: begin
						direct = GPR21[fileAddr[3:0]];
					end

					2'b11: begin
						direct = GPR31[fileAddr[3:0]];
					end
				endcase
			end
		endcase
	end

	// write block
	integer index;
	always @(posedge clk) begin
		if (rst) begin
			status <= `DATA_WIDTH'b0001_1xxx;
			FSReg <= `DATA_WIDTH'b0000_0000;
			portA <= `IO_A_WIDTH'b0000;
			portB <= `IO_B_WIDTH'b0000_0000;
			portC <= `IO_C_WIDTH'b0000_0000;

			for(index = 8 ; index < 16 ; index = index + 1) begin
				GPR00[index] <= `DATA_WIDTH'b0000_0000;
			end

			for(index = 0 ; index < 16 ; index = index + 1) begin
				GPR01[index] <= `DATA_WIDTH'b0000_0000;
				GPR11[index] <= `DATA_WIDTH'b0000_0000;
				GPR21[index] <= `DATA_WIDTH'b0000_0000;
				GPR31[index] <= `DATA_WIDTH'b0000_0000;
			end
		end
		else begin
			case (writeCommand)
				`RF_WR_FSR____IND,
				`RF_WR_FSR_STATUS: begin
					if (writeCommand == `RF_WR_FSR_STATUS) begin
						status <= statusIn;
					end

					case (fileAddr)
						`ADDR_INDF: begin
							case (FSReg[4:0])
								`ADDR_INDF: begin
									// intentionally blank; do nothing
								end

								`ADDR_TMR0: begin
									// intentionally blank; do nothing
								end

								`ADDR_PCL: begin
									// indirect = pcIn[7:0];
									// intentionally blank; do nothing
								end

								`ADDR_STATUS: begin
									// indirect = status;
									status <= {writeDataIn[7:5], status[4:3], writeDataIn[2:0]};
								end

								`ADDR_FSR: begin
									FSReg <= writeDataIn;
								end

								`ADDR_PORTA: begin
									portA <= writeDataIn[`IO_A_WIDTH - 1:0];
								end

								`ADDR_PORTB: begin
									portB <= writeDataIn;
								end

								`ADDR_PORTC: begin
									portC <= writeDataIn;
								end

								// GPR00
								5'h08,
								5'h09,
								5'h0A,
								5'h0B,
								5'h0C,
								5'h0D,
								5'h0E,
								5'h0F: begin
									GPR00[FSReg[3:0]] <= writeDataIn;
								end

								// GPRX1
								5'h10,
								5'h11,
								5'h12,
								5'h13,
								5'h14,
								5'h15,
								5'h16,
								5'h17,
								5'h18,
								5'h19,
								5'h1A,
								5'h1B,
								5'h1C,
								5'h1D,
								5'h1E,
								5'h1F: begin
									case (FSReg[6:5])
										2'b00: begin
											GPR01[FSReg[3:0]] <= writeDataIn;
										end

										2'b01: begin
											GPR11[FSReg[3:0]] <= writeDataIn;
										end

										2'b10: begin
											GPR21[FSReg[3:0]] <= writeDataIn;
										end

										2'b11: begin
											GPR31[FSReg[3:0]] <= writeDataIn;
										end
									endcase
								end
							endcase
						end

						`ADDR_TMR0: begin
							// intentionally blank; do nothing
						end

						`ADDR_PCL: begin
							// intentionally blank; do nothing
							// TODO: ?????
						end

						// TODO: protection needed for STATUS register.
						//       see section 4.6 of the datasheet for more information.
						`ADDR_STATUS: begin
							status <= {writeDataIn[7:5], status[4:3], writeDataIn[2:0]};
						end

						`ADDR_FSR: begin
							FSReg <= writeDataIn;
						end

						`ADDR_PORTA: begin
							portA <= writeDataIn[`IO_A_WIDTH - 1:0];
						end

						`ADDR_PORTB: begin
							portB <= writeDataIn;
						end

						`ADDR_PORTC: begin
							portC <= writeDataIn;
						end

						5'h08,
						5'h09,
						5'h0A,
						5'h0B,
						5'h0C,
						5'h0D,
						5'h0E,
						5'h0F: begin
							GPR00[fileAddr[3:0]] <= writeDataIn;
						end

						// GPRX1
						5'h10,
						5'h11,
						5'h12,
						5'h13,
						5'h14,
						5'h15,
						5'h16,
						5'h17,
						5'h18,
						5'h19,
						5'h1A,
						5'h1B,
						5'h1C,
						5'h1D,
						5'h1E,
						5'h1F: begin
							case (FSReg[6:5])
								2'b00: begin
									GPR01[fileAddr[3:0]] <= writeDataIn;
								end

								2'b01: begin
									GPR11[fileAddr[3:0]] <= writeDataIn;
								end

								2'b10: begin
									GPR21[fileAddr[3:0]] <= writeDataIn;
								end

								2'b11: begin
									GPR31[fileAddr[3:0]] <= writeDataIn;
								end
							endcase
						end
					endcase
				end

				`RF_WR_____STATUS: begin
					status <= statusIn;
				end

				`RF_WR________FSR: begin
					// FSReg <= {1'b0, FSReg[6:5], writeDataIn[4:0]};
					FSReg <= writeDataIn;
				end

				default: begin // include RF_WR________NOP
					// intentionally blank; do nothing
				end
			endcase
		end
	end

	
	/////////////////
	// monitoring only
	/////////////////////////////////
	wire[`DATA_WIDTH - 1:0] MON_FSR;
	wire[`DATA_WIDTH - 1:0] MON_PCL;
	wire[`DATA_WIDTH - 1:0] MON_STATUS;
	assign MON_FSR = FSReg;
	assign MON_PCL = pcIn[7:0];
	assign MON_STATUS = status;

	wire[1:0] MON_GPRBank;
	wire[4:0] MON_GPRSelect;
	assign {MON_GPRBank, MON_GPRSelect} = FSReg[6:0];

	wire[`DATA_WIDTH - 1:0] MON_GPR_0_0;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_1;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_2;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_3;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_4;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_5;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_6;
	wire[`DATA_WIDTH - 1:0] MON_GPR_0_7;
	assign MON_GPR_0_0 = GPR00[8];
	assign MON_GPR_0_1 = GPR00[9];
	assign MON_GPR_0_2 = GPR00[10];
	assign MON_GPR_0_3 = GPR00[11];
	assign MON_GPR_0_4 = GPR00[12];
	assign MON_GPR_0_5 = GPR00[13];
	assign MON_GPR_0_6 = GPR00[14];
	assign MON_GPR_0_7 = GPR00[15];

	reg[`DATA_WIDTH - 1:0] MON_GPR_0;
	reg[`DATA_WIDTH - 1:0] MON_GPR_1;
	reg[`DATA_WIDTH - 1:0] MON_GPR_2;
	reg[`DATA_WIDTH - 1:0] MON_GPR_3;
	reg[`DATA_WIDTH - 1:0] MON_GPR_4;
	reg[`DATA_WIDTH - 1:0] MON_GPR_5;
	reg[`DATA_WIDTH - 1:0] MON_GPR_6;
	reg[`DATA_WIDTH - 1:0] MON_GPR_7;
	reg[`DATA_WIDTH - 1:0] MON_GPR_8;
	reg[`DATA_WIDTH - 1:0] MON_GPR_9;
	reg[`DATA_WIDTH - 1:0] MON_GPR_A;
	reg[`DATA_WIDTH - 1:0] MON_GPR_B;
	reg[`DATA_WIDTH - 1:0] MON_GPR_C;
	reg[`DATA_WIDTH - 1:0] MON_GPR_D;
	reg[`DATA_WIDTH - 1:0] MON_GPR_E;
	reg[`DATA_WIDTH - 1:0] MON_GPR_F;
	// always @(FSReg[6:5] or GPR00 or GPR01 or GPR11 or GPR21 or GPR31) begin
	always @(*) begin
		case (FSReg[6:5])
			2'b00: begin
				MON_GPR_0 = GPR01[4'b0000];
				MON_GPR_1 = GPR01[4'b0001];
				MON_GPR_2 = GPR01[4'b0010];
				MON_GPR_3 = GPR01[4'b0011];
				MON_GPR_4 = GPR01[4'b0100];
				MON_GPR_5 = GPR01[4'b0101];
				MON_GPR_6 = GPR01[4'b0110];
				MON_GPR_7 = GPR01[4'b0111];
				MON_GPR_8 = GPR01[4'b1000];
				MON_GPR_9 = GPR01[4'b1001];
				MON_GPR_A = GPR01[4'b1010];
				MON_GPR_B = GPR01[4'b1011];
				MON_GPR_C = GPR01[4'b1100];
				MON_GPR_D = GPR01[4'b1101];
				MON_GPR_E = GPR01[4'b1110];
				MON_GPR_F = GPR01[4'b1111];
			end

			2'b01: begin
				MON_GPR_0 = GPR11[4'b0000];
				MON_GPR_1 = GPR11[4'b0001];
				MON_GPR_2 = GPR11[4'b0010];
				MON_GPR_3 = GPR11[4'b0011];
				MON_GPR_4 = GPR11[4'b0100];
				MON_GPR_5 = GPR11[4'b0101];
				MON_GPR_6 = GPR11[4'b0110];
				MON_GPR_7 = GPR11[4'b0111];
				MON_GPR_8 = GPR11[4'b1000];
				MON_GPR_9 = GPR11[4'b1001];
				MON_GPR_A = GPR11[4'b1010];
				MON_GPR_B = GPR11[4'b1011];
				MON_GPR_C = GPR11[4'b1100];
				MON_GPR_D = GPR11[4'b1101];
				MON_GPR_E = GPR11[4'b1110];
				MON_GPR_F = GPR11[4'b1111];
			end

			2'b10: begin
				MON_GPR_0 = GPR21[4'b0000];
				MON_GPR_1 = GPR21[4'b0001];
				MON_GPR_2 = GPR21[4'b0010];
				MON_GPR_3 = GPR21[4'b0011];
				MON_GPR_4 = GPR21[4'b0100];
				MON_GPR_5 = GPR21[4'b0101];
				MON_GPR_6 = GPR21[4'b0110];
				MON_GPR_7 = GPR21[4'b0111];
				MON_GPR_8 = GPR21[4'b1000];
				MON_GPR_9 = GPR21[4'b1001];
				MON_GPR_A = GPR21[4'b1010];
				MON_GPR_B = GPR21[4'b1011];
				MON_GPR_C = GPR21[4'b1100];
				MON_GPR_D = GPR21[4'b1101];
				MON_GPR_E = GPR21[4'b1110];
				MON_GPR_F = GPR21[4'b1111];
			end

			2'b11: begin
				MON_GPR_0 = GPR31[4'b0000];
				MON_GPR_1 = GPR31[4'b0001];
				MON_GPR_2 = GPR31[4'b0010];
				MON_GPR_3 = GPR31[4'b0011];
				MON_GPR_4 = GPR31[4'b0100];
				MON_GPR_5 = GPR31[4'b0101];
				MON_GPR_6 = GPR31[4'b0110];
				MON_GPR_7 = GPR31[4'b0111];
				MON_GPR_8 = GPR31[4'b1000];
				MON_GPR_9 = GPR31[4'b1001];
				MON_GPR_A = GPR31[4'b1010];
				MON_GPR_B = GPR31[4'b1011];
				MON_GPR_C = GPR31[4'b1100];
				MON_GPR_D = GPR31[4'b1101];
				MON_GPR_E = GPR31[4'b1110];
				MON_GPR_F = GPR31[4'b1111];
			end
		endcase
	end
	//////////////////////////////////////////////////


endmodule