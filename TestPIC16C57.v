`timescale 1ns / 1ps

`include "CPUDef.v"

`define SIGNAL_READY   4'h1
`define SIGNAL_BUSY    4'h4
`define SIGNAL_CHECK   4'hA
`define SIGNAL_RESULTH 4'hD
`define SIGNAL_RESULTV 4'hE
`define SIGNAL_END     4'hF

`define STAGE_INIT    3'b000
`define STAGE_READ    3'b100
`define STAGE_RESULTH 3'b101
`define STAGE_RESULTV 3'b110
`define STAGE_END     3'b111

module TestPIC16C57(
	);

	reg clk;
	reg rst;

	wire[`IO_A_WIDTH - 1:0] portAIO;
	wire[`IO_B_WIDTH - 1:0] portBIO;
	wire[`IO_C_WIDTH - 1:0] portCIO;

	reg[3:0] stage;

	reg[`IO_B_WIDTH - 1:0] value1;
	reg[`IO_C_WIDTH - 1:0] value2;
	assign portBIO = (stage == `STAGE_RESULTH || stage == `STAGE_RESULTV) ? 8'hzz : value1;
	assign portCIO = (stage == `STAGE_RESULTH || stage == `STAGE_RESULTV) ? 8'hzz : value2;

	reg[`IO_C_WIDTH - 1:0] portAPrev;

	initial begin
		$init;

		clk = 1;
		rst = 1;
		#0.5 rst = 0; // synchronous active-high reset

		portAPrev = 0;
		stage = `STAGE_INIT;
		// $display("init stage");

		// #2000000 $stop();
	end

	always begin
		#5 clk = ~clk;
	end

	always @(portAIO or portCIO or portBIO) begin
		if (portAPrev != portAIO) begin // on port a value chage
			portAPrev = portAIO;

			if (stage == `STAGE_INIT) begin
				if (portAIO == `SIGNAL_CHECK) begin
					value1 = $finished;
					if (value1 == 8'hFF) begin
						$display("==== END ====");
						#1000 $stop;
					end
					else begin
						stage = `STAGE_READ;
						// $display("read stage");
					end
				end
			end

			else if (stage == `STAGE_READ) begin
				if (portAIO == `SIGNAL_READY) begin
					value1 = $readNextAdjacentPixel;
				end
				else if (portAIO == `SIGNAL_RESULTH) begin
					// $display("result h stage");
					stage = `STAGE_RESULTH;
				end
			end

			else if (stage == `STAGE_RESULTH) begin
				if (portAIO == `SIGNAL_READY) begin
					// $printPortOutput({portBIO, portCIO});
					$storeConvolH({portBIO, portCIO});
				end
				else if (portAIO == `SIGNAL_RESULTV) begin
					// $display("result v stage");
					stage = `STAGE_RESULTV;
				end
			end

			else if (stage == `STAGE_RESULTV) begin
				if (portAIO == `SIGNAL_READY) begin
					// $printPortOutput({portBIO, portCIO});
					$storeConvolV({portBIO, portCIO});
					$storePixel;
				end
				else if (portAIO == `SIGNAL_CHECK) begin
					// $display("checking end...");
					value1 = $finished;
					if (value1 == 8'hFF) begin
						$display("==== END ====");
						#1000 $stop;
					end
					else begin
						stage = `STAGE_READ;
						// $display("read stage");
					end
				end
			end
		end
	end

	PIC16C57 duv(
		.clk(clk),
		.rst(rst),

		.portAIO(portAIO),
		.portBIO(portBIO),
		.portCIO(portCIO)
	);

endmodule
