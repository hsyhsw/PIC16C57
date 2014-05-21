`timescale 1ns/1ps

`include "CPUDef.v"

module Stack(
		input clk,
		input rst,
		input[1:0] commandIn,
		input[`PC_WIDTH - 1:0] in,
		output[`PC_WIDTH - 1:0] topOut
	);

	reg ptr;
	reg[`PC_WIDTH - 1:0] frame[1:0];

	wire[`PC_WIDTH - 1:0] MON_frame0;
	wire[`PC_WIDTH - 1:0] MON_frame1;
	assign MON_frame0 = frame[0];
	assign MON_frame1 = frame[1];

	assign topOut = frame[~ptr];

	always @(posedge clk) begin
		if (rst) begin
			ptr <= 0;
			frame[0] <= 0;
			frame[1] <= 0;
		end
		else begin
			case (commandIn)
				`STK_PUSH: begin
					ptr <= ~ptr; // ++ptr
					frame[ptr] <= in;
				end

				`STK_POP: begin
					ptr <= ~ptr; // --ptr
				end

				default: begin
					// intentionally blank; do nothing
				end
			endcase
		end
	end

endmodule