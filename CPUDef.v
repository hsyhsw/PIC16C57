`ifndef _CPUDEF_V_
`define _CPUDEF_V_

//CPU States
`define CU_FE_STATE_BITS   2
`define CU_EX_STATE_BITS   5
//Fetch
`define FE_Q1_____INCPC    `CU_FE_STATE_BITS'b00
`define FE_Q2______IDLE    `CU_FE_STATE_BITS'b01
`define FE_Q3______IDLE    `CU_FE_STATE_BITS'b10
`define FE_Q4_____FETCH    `CU_FE_STATE_BITS'b11
//Execute
`define EX_Q1_TEST_SKIP `CU_EX_STATE_BITS'b00100 //Q1
`define EX_Q2_______FSR `CU_EX_STATE_BITS'b00101 //Q2
`define EX_Q2______ELSE `CU_EX_STATE_BITS'b00110
`define EX_Q3_______ALU `CU_EX_STATE_BITS'b00111 //Q3
`define EX_Q4______CLRF `CU_EX_STATE_BITS'b01000 //Q4
`define EX_Q4______CLRW `CU_EX_STATE_BITS'b01001
`define EX_Q4______DECF `CU_EX_STATE_BITS'b01010
`define EX_Q4_____MOVWF `CU_EX_STATE_BITS'b01011
`define EX_Q4_____SUBWF `CU_EX_STATE_BITS'b01100
`define EX_Q4____CLRWDT `CU_EX_STATE_BITS'b01101
`define EX_Q4____OPTION `CU_EX_STATE_BITS'b01110
`define EX_Q4_____SLEEP `CU_EX_STATE_BITS'b01111
`define EX_Q4______TRIS `CU_EX_STATE_BITS'b10000
`define EX_Q4_______FSZ `CU_EX_STATE_BITS'b10001
`define EX_Q4_____SWAPF `CU_EX_STATE_BITS'b10010
`define EX_Q4___00_ELSE `CU_EX_STATE_BITS'b10011
`define EX_Q4_______BXF `CU_EX_STATE_BITS'b10100
`define EX_Q4_____BTFSX `CU_EX_STATE_BITS'b10101
`define EX_Q4____ALUXLW `CU_EX_STATE_BITS'b10110 //AND, IOR, XOR
`define EX_Q4_____MOVLW `CU_EX_STATE_BITS'b10111
`define EX_Q4______GOTO `CU_EX_STATE_BITS'b11000
`define EX_Q4______CALL `CU_EX_STATE_BITS'b11001
`define EX_Q4_____RETLW `CU_EX_STATE_BITS'b11010
`define EX_Q4______ELSE `CU_EX_STATE_BITS'b11011
`define EX_Q4______MOVF `CU_EX_STATE_BITS'b11100
//End of CPU states

//ALU Functions
`define ALU_FUNC_WIDTH   5
`define ALU_SUBWF        `ALU_FUNC_WIDTH'b0_0000
`define ALU_ADDWF        `ALU_FUNC_WIDTH'b0_0001
`define ALU_ANDWF        `ALU_FUNC_WIDTH'b0_0010
`define ALU__COMF        `ALU_FUNC_WIDTH'b0_0011
`define ALU__DECF        `ALU_FUNC_WIDTH'b0_0100
`define ALU__INCF        `ALU_FUNC_WIDTH'b0_0101
`define ALU_IORWF        `ALU_FUNC_WIDTH'b0_0110
`define ALU___RLF        `ALU_FUNC_WIDTH'b0_0111
`define ALU___RRF        `ALU_FUNC_WIDTH'b0_1000
`define ALU_SWAPF        `ALU_FUNC_WIDTH'b0_1001
`define ALU_XORWF        `ALU_FUNC_WIDTH'b0_1010
`define ALU___BCF        `ALU_FUNC_WIDTH'b0_1011
`define ALU___BSF        `ALU_FUNC_WIDTH'b0_1100
`define ALU_ANDLW        `ALU_FUNC_WIDTH'b0_1101
`define ALU_IORLW        `ALU_FUNC_WIDTH'b0_1110
`define ALU_XORLW        `ALU_FUNC_WIDTH'b0_1111
`define ALU__IDLE        `ALU_FUNC_WIDTH'b1_0000
//End of ALU functions

//Instructions
`define INST_WIDTH      12
`define OP_TRIS_WIDTH    9
`define OP_BYTE7_WIDTH   7
`define OP_BYTE6_WIDTH   6
`define OP_BIT_WIDTH     4
`define OP_LITERAL_WIDTH 4
`define OP_GOTO_WIDTH    3
//Byte-oriented operations
`define I_ADDWF__6      `OP_BYTE6_WIDTH'b00_0111
`define I_ANDWF__6      `OP_BYTE6_WIDTH'b00_0101
`define I_COMF___6      `OP_BYTE6_WIDTH'b00_1001
`define I_DECF___6      `OP_BYTE6_WIDTH'b00_0011
`define I_DECFSZ_6      `OP_BYTE6_WIDTH'b00_1011
`define I_INCF___6      `OP_BYTE6_WIDTH'b00_1010
`define I_INCFSZ_6      `OP_BYTE6_WIDTH'b00_1111
`define I_IORWF__6      `OP_BYTE6_WIDTH'b00_0100
`define I_MOVF___6      `OP_BYTE6_WIDTH'b00_1000
`define I_RLF____6      `OP_BYTE6_WIDTH'b00_1101
`define I_RRF____6      `OP_BYTE6_WIDTH'b00_1100
`define I_SUBWF__6      `OP_BYTE6_WIDTH'b00_0010
`define I_SWAPF__6      `OP_BYTE6_WIDTH'b00_1110
`define I_XORWF__6      `OP_BYTE6_WIDTH'b00_0110
`define I_MOVWF__7     `OP_BYTE7_WIDTH'b000_0001
`define I_CLRF___7     `OP_BYTE7_WIDTH'b000_0011
`define I_NOP___12   `INST_WIDTH'b0000_0000_0000
`define I_CLRW__12   `INST_WIDTH'b0000_0100_0000
//Bit-oriented operations
`define I_BCF____4           `OP_BIT_WIDTH'b0100
`define I_BSF____4           `OP_BIT_WIDTH'b0101
`define I_BTFSC__4           `OP_BIT_WIDTH'b0110
`define I_BTFSS__4           `OP_BIT_WIDTH'b0111
//Literal operations
`define I_GOTO___3           `OP_GOTO_WIDTH'b101
`define I_ANDLW__4       `OP_LITERAL_WIDTH'b1110
`define I_CALL___4       `OP_LITERAL_WIDTH'b1001
`define I_IORLW__4       `OP_LITERAL_WIDTH'b1101
`define I_MOVLW__4       `OP_LITERAL_WIDTH'b1100
`define I_RETLW__4       `OP_LITERAL_WIDTH'b1000
`define I_XORLW__4       `OP_LITERAL_WIDTH'b1111
`define I_TRIS___4   `OP_TRIS_WIDTH'b0_0000_0000
`define I_CLRWDT_4   `INST_WIDTH'b0000_0000_0100
`define I_OPTION_4   `INST_WIDTH'b0000_0000_0010
`define I_SLEEP__4   `INST_WIDTH'b0000_0000_0011
//End of instructions

//Misc. Port Width
`define DATA_WIDTH       8
`define ALU_DATA_WIDTH   8
`define ALU_STATUS_WIDTH 3
`define PC_WIDTH         11

//Register File
`define REGFILE_ADDR_WIDTH 7
`define IO_A_WIDTH         4
`define IO_B_WIDTH         8
`define IO_C_WIDTH         8
`define BANK0_FSR65        2'b00
`define BANK1_FSR65        2'b01
`define BANK2_FSR65        2'b10
`define BANK3_FSR65        2'b11
`define ADDR_INDF          5'b0_0000
`define ADDR_TMR0          5'b0_0001
`define ADDR_PCL           5'b0_0010
`define ADDR_STATUS        5'b0_0011
`define ADDR_FSR           5'b0_0100
`define ADDR_PORTA         5'b0_0101
`define ADDR_PORTB         5'b0_0110
`define ADDR_PORTC         5'b0_0111
`define RF_WR________NOP   3'b000
`define RF_WR_____STATUS   3'b001
`define RF_WR_FSR____IND   3'b010
`define RF_WR_FSR_STATUS   3'b011
`define RF_WR________FSR   3'b100

//Stack
`define STK_NOP          2'b00
`define STK_PUSH         2'b01
`define STK_POP          2'b10

`endif //_CPUDEF_V_
