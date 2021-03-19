`default_nettype none

/*
instruction	opcode	operand		operation		clocks
ADD:
----
ADDi imm	00 01	16 bit value	imm+(A) --> A		3
ADDm addr	00 02	16 bit address	(addr)+(A) --> A	4
ADDpc		00 04	null operand	PC+(A) --> A		3

Branch:
-------
BVS addr	00 08	16 bit address	(addr) --> PC if <v>=1	3

Load:
-----
LDAi imm	00 10	16 bit value	imm --> A		3
LDAm addr	00 20	16 bit address	(addr) --> A		3
LDApc 		00 40	null operand	PC --> A		3

Store:
------
STAm addr	00 80	16 bit address	A --> (addr)		3
STApc PC	01 00	null operand	A --> PC		3
*/

module f4(clk, rstn);

parameter DW = 16;
parameter AW = 16;
parameter PROGFILE = "prog.list";

input clk;
input rstn;

reg [DW:0]   A_reg; // = 0;
reg [DW-1:0] I_reg; // = 0;
reg [DW-1:0] OP_reg; // = 0;
reg [DW-1:0] PC_reg; // = 0;
reg [DW-1:0] addr;
wire [DW-1:0] op_data;
wire [DW-1:0] i_data;
wire overflow_bit;

assign overflow_bit = A_reg[DW];

// Components

genram #(.DW(DW), .AW(AW), .ROMFILE(PROGFILE))
   RAM (.clk(clk),
	.rw(mem_rw),
	.addr(addr),
	.data_in(A_reg[DW-1:0]),
	.data_out({op_data, i_data}));

// Controller

localparam ADDI      = 16'b00000000_00000001;
localparam ADDM      = 16'b00000000_00000010;
localparam ADDPC     = 16'b00000000_00000100;
localparam BVS       = 16'b00000000_00001000;
localparam LDAI      = 16'b00000000_00010000;
localparam LDAM      = 16'b00000000_00100000;
localparam LDAPC     = 16'b00000000_01000000;
localparam STAM      = 16'b00000000_10000000;
localparam STAPC     = 16'b00000001_00000000;

localparam ADD_MASK  = 16'b00000000_00000111;
localparam LDA_MASK  = 16'b00000000_01110000;
localparam STA_MASK  = 16'b00000001_10000000;

localparam IM_MASK   = 16'b00000000_00010001;
localparam ADDR_MASK = 16'b00000000_10101010;
localparam PC_MASK   = 16'b00000001_01000100;

reg [2:0] state = 0;
reg [2:0] next_state = 0;

localparam STATE_INIT      = 0;
localparam STATE_FETCH     = 1;
localparam STATE_DECODE    = 2;
localparam STATE_WAIT      = 3; // Wait state to give to load the ADDR for ADDm
localparam STATE_EXEC      = 4;

wire null_op;
wire addr_op;
wire add_op;
wire lda_op;
wire sta_op;
assign addr_op = (I_reg & ADDR_MASK) != 0;
assign add_op  = (I_reg & ADD_MASK) != 0;
assign lda_op  = (I_reg & LDA_MASK) != 0;
assign sta_op  = (I_reg & STA_MASK) != 0;

// Signals
reg  mem_rw = 0;
assign null_op = (state == STATE_DECODE && (I_reg & PC_MASK) != 0);

// Handle I_reg
always @(posedge clk)
	if (!rstn)
		I_reg <= 0;
	else if (state == STATE_FETCH)
		I_reg <= i_data;

// Handle OP_reg
always @(posedge clk)
	if (!rstn)
		OP_reg <= 0;
	else if (state == STATE_WAIT)
		OP_reg <= i_data;
	else if (state == STATE_FETCH && !null_op)
		OP_reg <= op_data;

// Handle accumulator
always @(posedge clk)
	if (!rstn)
		A_reg <= 0;
	else if (state == STATE_EXEC)
		case (I_reg)
			ADDI,
			ADDM:
				A_reg <= {1'b0,A_reg[DW-1:0]} + {1'b0,OP_reg};
			ADDPC:
				A_reg <= {1'b0,A_reg[DW-1:0]} + {1'b0,PC_reg};
			LDAI:
				A_reg <= {1'b0,OP_reg};
			LDAM:
				A_reg <= {1'b0,i_data};
			LDAPC:
				A_reg <= {1'b0,PC_reg};
		endcase

// Advance state
always @(posedge clk)
	state <= (!rstn) ? STATE_INIT : next_state;

// Advance PC
always @(posedge clk)
	if (!rstn)
		PC_reg <= 0;
	else if (state == STATE_DECODE) begin
		if (null_op)
			PC_reg <= (I_reg == STAPC) ? A_reg : PC_reg + 1;
		else
			PC_reg <= PC_reg + 2;
	end
	else if (state == STATE_WAIT && I_reg == BVS && overflow_bit)
		PC_reg <= i_data;

always @(*) begin
	// Default signal values
	mem_rw = 1;
	addr = PC_reg;
	next_state = STATE_FETCH;
	case (state)
		STATE_INIT: begin
		end
		STATE_FETCH:
			next_state = STATE_DECODE;
		STATE_DECODE: begin
			addr = (addr_op) ? OP_reg : PC_reg;
			mem_rw = !(I_reg == STAM);
			if (I_reg == ADDM || I_reg == BVS)
				next_state = STATE_WAIT;
			else
				next_state = STATE_EXEC;
		end
		STATE_WAIT:
			next_state = STATE_EXEC;
	endcase
end

endmodule
