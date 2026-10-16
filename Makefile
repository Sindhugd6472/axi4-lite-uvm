# AXI4-Lite UVM Makefile for Verilator

# Directories
RTL_DIR = rtl
TB_DIR = tb

# Files
RTL_FILES = $(RTL_DIR)/axi_slave_mem.sv
TB_FILES = $(TB_DIR)/axi_if.sv \
           $(TB_DIR)/axi_pkg.sv \
           $(TB_DIR)/tb_top.sv

# UVM Path
UVM_HOME ?=
VERILATOR ?= verilator

# Verilator flags
VFLAGS = --binary -j 2 \
         --trace \
         --timing \
         -Wall \
         -Wno-fatal \
         --top-module tb_top

# Default target
.PHONY: all
all: compile

# Compile
.PHONY: compile
compile:
	@test -f "$(UVM_HOME)/src/uvm_pkg.sv" || (echo "Set UVM_HOME to a supported UVM source checkout"; exit 1)
	$(VERILATOR) $(VFLAGS) +incdir+$(UVM_HOME)/src +incdir+$(TB_DIR) $(UVM_HOME)/src/uvm_pkg.sv $(RTL_FILES) $(TB_FILES)

# Run specific test
.PHONY: run
run:
	@echo "Running AXI4-Lite test..."
	./obj_dir/Vtb_top +UVM_TESTNAME=axi_write_read_test +UVM_VERBOSITY=UVM_MEDIUM

# Run random test
.PHONY: run_random
run_random:
	./obj_dir/Vtb_top +UVM_TESTNAME=axi_random_test +UVM_VERBOSITY=UVM_MEDIUM

# View waveform
.PHONY: wave
wave:
	gtkwave axi_tb.vcd &

# Clean
.PHONY: clean
clean:
	rm -rf obj_dir *.vcd *.log

# Help
.PHONY: help
help:
	@echo "AXI4-Lite UVM Verification Makefile"
	@echo "Usage:"
	@echo "  make compile      - Compile the testbench"
	@echo "  make run          - Run write-read test"
	@echo "  make run_random   - Run random test"
	@echo "  make wave         - View waveforms"
	@echo "  make clean        - Clean build files"

.PHONY: rtl-test
rtl-test:
	iverilog -g2012 -s axi_rtl_tb -o /tmp/axi_rtl_sim rtl/axi_slave_mem.sv tests/axi_rtl_tb.sv
	vvp /tmp/axi_rtl_sim
