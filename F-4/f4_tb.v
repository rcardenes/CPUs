`define STRINGIFY(x) `"x`"
// `define OUTPUT  "prog.vcd"

module f4_tb();

parameter DW = 16;
parameter AW = 16;
parameter SECONDS = 100;

//-- Registro para generar la señal de reloj
reg clk = 0;

reg rstn = 0;

//-- Instanciar el componente
f4 #(.DW(DW), .AW(AW), .PROGFILE(`STRINGIFY(`PROGFILE)))
  dut(
    .clk(clk),
    .rstn(rstn)
  );

//-- Generador de reloj. Periodo 2 unidades
always #1 clk = ~clk;

//-- Proceso al inicio
initial begin

  //-- Fichero donde almacenar los resultados
  $dumpfile(`STRINGIFY(`OUTPUT));
  $dumpvars(0, f4_tb);

  #1 rstn <= 1;

  #SECONDS $display("FIN de la simulacion");
  $finish;
end

endmodule
