# AXI4-Lite UVM Makefile for Verilator

# Directories
RTL_DIR = rtl
TB_DIR = tb

# Files
RTL_FILES = $(RTL_DIR)/axi_slave_mem.sv
TB_FILES = $(TB_DIR)/axi_if.sv \
           $(TB_DIR)/tb_top.sv

# UVM Path
UVM_HOME = /usr/local/share/verilator/include/vltstd

# Verilator flags
VFLAGS = --cc --exe --build -j 0 \
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
	verilator $(VFLAGS) $(RTL_FILES) $(TB_FILES)

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
