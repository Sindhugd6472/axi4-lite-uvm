# AXI4-Lite UVM Verification Environment

SystemVerilog/UVM testbench implementation for an AXI4-Lite slave memory module. Simulator execution has not been independently validated in this review.

## 📁 Project Structure
```
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
```

## 🛠️ Simulation

### Questa/ModelSim with UVM support

The Makefile uses `vlib`, `vlog`, and `vsim` and compiles the RTL, AXI interface, UVM package, and testbench top in dependency order.

```bash
make run
make run_random
```

You can also select a registered UVM test with `make run UVM_TEST=axi_random_test`.

**Validation status:** These commands are provided as a starting point; the current review did not execute them on a licensed UVM simulator. This repository does not currently include automated simulation CI. Before claiming a passing regression, confirm compile success, UVM error/fatal counts, scoreboard results, and expected waveform behavior.

The previous Verilator Makefile used `--exe` without a C++ harness and was not a reproducible UVM build. Other simulators such as VCS or Xcelium may be usable, but their commands need to be validated for the installed versions.

## 🧪 Available Tests

- axi_write_read_test - Basic write followed by read verification

- axi_random_test - Randomized transaction testing

## 📊 Statistics

- **Total Lines**: 945

- **RTL**: 139 lines

- **Testbench**: 806 lines

- **Files**: 12

## ⚙️ Features

✅ Full UVM architecture (driver, monitor, scoreboard, coverage)

✅ AXI4-Lite protocol-focused stimulus and checking (full compliance not established)

✅ Write/Read transaction checking

✅ Response verification (OKAY, SLVERR)

✅ Functional coverage for addresses and operations

✅ Randomized sequences

## 📝 Note

This testbench uses SystemVerilog UVM. Verilator's UVM support is experimental - use commercial simulators (QuestaSim, Xcelium, VCS, Vivado) for production verification.
