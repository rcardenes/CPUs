SIMSRC=f4_tb.v
OTHER=f4 genram
SIMPROGS=$(patsubst %.list,%.vcd,$(wildcard *.list))
ALL=$(wildcard *.v)
OTHERSRC=$(OTHER:=.v)
BIN=$(TARGET:=.bin)
NEXTPNR_OPT=--hx8k --package tq144:4k --pcf-allow-unconstrained

all: sim

sim: $(SIMPROGS)

sint: $(BIN)

%.vcd: %.list $(ALL)
	iverilog -DOUTPUT="$@" -DPROGFILE="$<" -y $(dir $<) -o $(@:.vcd=.out) $(SIMSRC)
	./$(@:.vcd=.out)

%.bin: %.v %.pcf $(OTHERSRC)
	yosys -p "synth_ice40 -top $(<:.v=) -json $(<:.v=.json)" $< $(OTHERSRC) > /dev/null
	nextpnr-ice40 $(NEXTPNR_OPT) --json $(<:.v=.json) --pcf $(<:.v=.pcf) --asc $(<:.v=.asc) > /dev/null
	icepack $(<:.v=.asc) $@ > /dev/null

clean:
	rm -f *.bin *.asc *.json *.out *.vcd *.blif *~

flash-%: %.bin %.v %.pcf $(OTHERSRC)
	iceprog -d i:0x0403:0x6010:0 $<

.PHONY: all clean sim
