`default_nettype none
// Memory adapted for the F-4 processor, returning two consecutive words
// when reading

// rw == 1 -> Lectura
//    == 0 -> Escritura
module genram #(
	parameter AW = 5,
	parameter DW = 5)
	(
	input wire clk,
	input wire [DW-1:0] data_in,
	input wire rw,
	input wire [AW-1:0] addr,
	output reg [(DW * 2)-1:0] data_out);

// Reglas
//  - Un único reloj
//  - Sensibilidad al mismo flanco
//  - Registrar entradas a circuitos combinacionales
//  - Registrar entradas a circuitos secuenciales
//  - Las salidas de un combinacional deben ser a:
//    - Entrada de OTRO combinacional
//    - Entrada síncrona
//    - Salida de circuito síncrono

parameter ROMFILE = "prog.list";
localparam NPOS = 2 ** AW;
localparam ONLYONE = NPOS - 2;

reg [DW-1:0] ram [0:NPOS-1];

always @(posedge clk)
	if (rw == 0)
		ram[addr] <= data_in;
	else if (addr == ONLYONE)
		data_out[DW-1:0] <= ram[addr];
	else if (addr < ONLYONE)
		data_out <= {ram[addr+1],ram[addr]};

// Inicialización

initial begin
	$readmemh(ROMFILE, ram);
end

endmodule
