# AXI4-Lite UVM simulation with Questa/ModelSim.
# Requires a simulator installation with UVM support and vlog/vsim on PATH.
# Not validated in this environment; see README for simulator notes.
SHELL := /bin/sh
VLOG ?= vlog
VSIM ?= vsim
UVM_TEST ?= axi_write_read_test

RTL := rtl/axi_slave_mem.sv
TB := tb/axi_if.sv tb/axi_pkg.sv tb/tb_top.sv

.PHONY: all compile run run_random run_protocol wave clean help
all: compile

compile:
	vlib work
	$(VLOG) -sv +incdir+tb $(RTL) $(TB)

run: compile
	$(VSIM) -c tb_top +UVM_TESTNAME=$(UVM_TEST) -do "onerror {quit -code 1}; run -all; quit -f"

run_random: compile
	$(VSIM) -c tb_top +UVM_TESTNAME=axi_random_test -do "onerror {quit -code 1}; run -all; quit -f"

run_protocol: compile
	$(VSIM) -c tb_top +UVM_TESTNAME=axi_protocol_test -do "onerror {quit -code 1}; run -all; quit -f"

wave:
	gtkwave axi_tb.vcd

clean:
	rm -rf work transcript vsim.wlf *.vcd *.log

help:
	@echo "make run         - Compile and run axi_write_read_test in Questa/ModelSim"
	@echo "make run_random  - Compile and run axi_random_test"
	@echo "make run_protocol - Compile and run axi_protocol_test (requires simulator validation)"
	@echo "make run UVM_TEST=axi_random_test - Select a registered UVM test"
	@echo "Requires Questa/ModelSim with UVM support; not a Verilator make flow."
