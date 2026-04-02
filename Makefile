# =============================================================================
# Makefile — DFT Mini Project
# Simulator: Icarus Verilog (iverilog/vvp)
# Waveform:  GTKWave
# =============================================================================

TARGET  = sim.vvp
WAVE    = wave.vcd

IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# RTL source files
RTL = rtl/scan_dff.v              \
      rtl/my_design.v             \
      rtl/scan_insertion_my_design.v \
      rtl/lfsr.v                  \
      rtl/decompressor.v          \
      rtl/misr.v                  \
      rtl/top.v

# Testbench
TB = tb/tb.v

CFLAGS = -Wall -g2012

# -----------------------------------------------------------------------
.PHONY: all compile run view clean help

all: run

## Compile RTL + testbench
compile:
	$(IVERILOG) $(CFLAGS) -o $(TARGET) $(TB) $(RTL)

## Run simulation (prints LBIST result to terminal)
run: compile
	$(VVP) $(TARGET)

## Open waveform in GTKWave
view:
	$(GTKWAVE) $(WAVE) &

## Full flow: compile → simulate → view waveform
simulate: run view

## Remove generated files
clean:
	rm -f $(TARGET) $(WAVE)

## Show this help
help:
	@echo "Targets:"
	@echo "  make          - compile and run simulation"
	@echo "  make compile  - compile only"
	@echo "  make run      - compile and simulate"
	@echo "  make view     - open GTKWave waveform viewer"
	@echo "  make simulate - run then open waveform"
	@echo "  make clean    - remove build artifacts"
