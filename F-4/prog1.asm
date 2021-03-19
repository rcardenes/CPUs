# ----
#  Test program to verify the functionality of ADDi/ADDm/LDAm/STAm/STApc
# ----
start:
ADDi prog
STApc
# Data zone
data:
DW 0x0000
DW 0x0010
DW 0xffff
prog:
ADDm (data)+1
STAm (data)+2
# Clear A to verify that STAm stored the value where it was supposed to
LDAm (data)
LDAm (data)+2
LDAi prog
STApc
