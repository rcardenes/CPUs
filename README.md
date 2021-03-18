# Experiments with FPGA and CPUs

These are my personal experiments writing CPUs in Verilog, using Open Source tools (Yosys, nextpnr, iverilog, etc).
I'm trying to touch several architectures (focusing on [MISC](https://en.wikipedia.org/wiki/Minimal_instruction_set_computer) and RISC).

The main target at the time are boards based on the Lattice iCE40 family, but it will shift with the need of more powerful hardware.

- F-4 is variation of the [F-4 MISC processor](http://www.dakeng.com/misc.html) from Dave Kowalczyk (of TurboCNC fame). It's a MISC with only 4 instructions. Not very useful beyond the learning experience.
