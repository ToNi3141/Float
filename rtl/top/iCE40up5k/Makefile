PROJ = FloatTest
PIN_DEF = up5k.pcf
DEVICE = up5k

NEXTPNR = nextpnr-ice40
NEXTPNR_ARGS = --opt-timing  
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

SRC = ./topUP5k.v
SRC += ../../other/Serial2AXIS.v
SRC += ../../other/SPI_Slave.v
SRC += ../../other/sfifo.v
SRC += ../../float/FloatSub.v
SRC += ../../float/FloatAdd.v
SRC += ../../float/FindExponent.v
SRC += ../../float/FloatMul.v
SRC += ../../float/IntToFloat.v

SYNTH_OUT = ./synth
YOSYS = yosys
NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICEPROG = iceprog
#YOSYSFLAGS = -p "synth_ice40 -top top -blif $(FPGA_BLIF_OUT) -json $(FPGA_JSON_OUT) -relut;"
YOSYSFLAGS = -p "synth_ice40 -top top -blif $(FPGA_BLIF_OUT) -json $(FPGA_JSON_OUT) -relut -abc2;" # '-abc2' can help to fit the timing an size requirements
FPGA_BLIF_OUT = $(SYNTH_OUT)/_fpga.blif
FPGA_JSON_OUT = $(SYNTH_OUT)/_fpga.json
FPGA_ASC_OUT = $(SYNTH_OUT)/_fpga.asc
FPGA_BIN_OUT = $(SYNTH_OUT)/_fpga.bin

all: FloatTest.bin

FloatTest.json:
	-mkdir $(SYNTH_OUT)
	$(YOSYS) -q $(YOSYSFLAGS) $(SRC) 

%.json: %.v 
	yosys -p 'synth_ice40 -json $@' $<

FloatTest.asc: FloatTest.json
	$(NEXTPNR) $(NEXTPNR_ARGS) --$(DEVICE) --pcf $(PIN_DEF) --asc $(FPGA_ASC_OUT) --json $(FPGA_JSON_OUT)

FloatTest.bin: FloatTest.asc
	$(ICEPACK) $(FPGA_ASC_OUT) $(FPGA_BIN_OUT)

prog: FloatTest.bin
	$(ICEPROG) -S $(FPGA_BIN_OUT)

flash: 
	$(ICEPROG) $(FPGA_BIN_OUT)

sram:
	$(ICEPROG) -S $(FPGA_BIN_OUT)

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
