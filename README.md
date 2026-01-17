# AXI4-Lite UVM Verification Environment

Complete UVM testbench for verifying an AXI4-Lite slave memory module.

## 📁 Project Structure
axi4-lite-uvm/
├── rtl/
│ └── axi_slave_mem.sv # DUT: AXI4-Lite slave memory
├── tb/
│ ├── axi_if.sv # AXI4-Lite interface
│ ├── axi_transaction.sv # Transaction class
│ ├── axi_master_driver.sv # Master driver
│ ├── axi_monitor.sv # Monitor
│ ├── axi_agent.sv # Agent
│ ├── axi_scoreboard.sv # Scoreboard with checker
│ ├── axi_coverage.sv # Functional coverage
│ ├── axi_env.sv # Environment
│ ├── axi_sequences.sv # Test sequences
│ ├── axi_test.sv # Test classes
│ ├── axi_pkg.sv # UVM package
│ └── tb_top.sv # Testbench top
└── Makefile

text

## 🛠️ Simulation

### QuestaSim / ModelSim
```bash
# Compile UVM library
vlib work
vlog -L $UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv

# Compile design
vlog rtl/axi_slave_mem.sv
vlog -L work tb/axi_if.sv tb/axi_pkg.sv tb/tb_top.sv

# Run test
vsim -c tb_top +UVM_TESTNAME=axi_write_read_test -do "run -all; quit"

# With GUI and waveforms
vsim tb_top +UVM_TESTNAME=axi_random_test
Xcelium (Cadence)
bash
xrun -uvm \
     -access +rwc \
     rtl/axi_slave_mem.sv \
     tb/axi_if.sv \
     tb/axi_pkg.sv \
     tb/tb_top.sv \
     +UVM_TESTNAME=axi_write_read_test
VCS (Synopsys)
bash
vcs -sverilog -ntb_opts uvm-1.2 \
    -timescale=1ns/1ps \
    rtl/axi_slave_mem.sv \
    tb/axi_if.sv \
    tb/axi_pkg.sv \
    tb/tb_top.sv \
    +UVM_TESTNAME=axi_random_test
Vivado Simulator
bash
xvlog -sv rtl/axi_slave_mem.sv tb/axi_if.sv tb/axi_pkg.sv tb/tb_top.sv -L uvm
xelab tb_top -L uvm -debug all
xsim work.tb_top -testplusarg UVM_TESTNAME=axi_write_read_test -runall
🧪 Available Tests
axi_write_read_test - Basic write followed by read verification

axi_random_test - Randomized transaction testing

📊 Statistics
Total Lines: 945

RTL: 139 lines

Testbench: 806 lines

Files: 12

⚙️ Features
✅ Full UVM architecture (driver, monitor, scoreboard, coverage)
✅ AXI4-Lite protocol compliance
✅ Write/Read transaction checking
✅ Response verification (OKAY, SLVERR)
✅ Functional coverage for addresses and operations
✅ Randomized sequences

📝 Note
This testbench uses SystemVerilog UVM. Verilator's UVM support is experimental - use commercial simulators (QuestaSim, Xcelium, VCS, Vivado) for production verification.
