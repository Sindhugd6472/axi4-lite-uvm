# AXI4-Lite UVM Verification Environment

SystemVerilog/UVM testbench implementation for an AXI4-Lite slave memory module. Two UVM tests were run successfully in EDA Playground using Siemens Questa 2025.2 and UVM 1.2, with implementation limitations noted below.

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

**Validation status:** The two EDA Playground simulations below were run with Siemens Questa 2025.2 / UVM 1.2. The local `make` commands have not been separately validated, and this repository does not include automated simulator CI. Saved playgrounds specify a named test in `run_test(...)`; the repository's `tb_top.sv` intentionally uses `run_test()` with `+UVM_TESTNAME` supplied by the Makefile.

The previous Verilator Makefile used `--exe` without a C++ harness and was not a reproducible UVM build. Other simulators such as VCS or Xcelium may be usable, but their commands need to be validated for the installed versions.

## 🧪 Executed UVM Tests (EDA Playground)

| Test | Writes | Reads | Read matches | Mismatches | UVM errors / fatals | Coverage reported | Saved run |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `axi_write_read_test` | 10 | 10 | 10 | 0 | 0 / 0 | 82.14% | [Write-read run](https://www.edaplayground.com/x/9BXQ) |
| `axi_random_test` | 19 | 20 | 20 | 0 | 0 / 0 | 82.14% | [Random run](https://www.edaplayground.com/x/haFZ) |

**Environment:** Siemens Questa 2025.2, UVM 1.2 (EDA Playground), November 11, 2026. Both runs compiled without errors. The simulator issued one nonfatal optimization warning about `+acc`.

**Limitations:** These tests pass the included scoreboard for the exercised stimulus; they do **not** demonstrate complete AXI4-Lite compliance. The DUT write-data condition `wvalid && !wready && awready` is a synchronization workaround for the current driver and does not handle every independent AW/W channel arrival order. A fully decoupled handshake design and directed backpressure tests are still needed. Random reads often access unwritten addresses and compare as zero. The reported coverage is a custom testbench metric, not complete AXI4-Lite protocol coverage.

## 🔬 Reproducing in EDA Playground

Place `rtl/axi_slave_mem.sv` in `design.sv`. In `testbench.sv`, include `axi_if.sv` before the `axi_pkg` package and include `tb_top.sv` after `endpackage`. Add the UVM class files as tabs (they are included by `axi_pkg.sv`). Select SystemVerilog/Verilog, UVM 1.2, and Siemens Questa 2025.2. In the playground's top module, use `run_test("axi_write_read_test")` or `run_test("axi_random_test")`. The repository version instead takes a `+UVM_TESTNAME` argument.

## 🔧 Updated protocol implementation — Questa regression results

With the updated RTL, driver, monitor, scoreboard and protocol assertions, these three tests were executed in EDA Playground with **Siemens Questa 2025.2 / UVM 1.2** on **November 11, 2026**:

| Test | Writes | Reads | Matches | Mismatches | Response errors | UVM errors / fatals | Reported coverage |
| --- | ---: | ---: | ---: | ---: | ---: | --- | ---: |
| `axi_protocol_test` | 7 | 7 | 7 | 0 | 0 | 0 / 0 | 73.81% |
| `axi_write_read_test` | 10 | 10 | 10 | 0 | 0 | 0 / 0 | 82.14% |
| `axi_random_test` | 19 | 20 | 20 | 0 | 0 | 0 / 0 | 82.14% |

All three compiled without errors; Questa printed a nonfatal `+acc` optimization warning. These figures come from the user-provided EDA Playground logs; the standalone `make` commands and automated CI have not been separately executed.

The implementation independently buffers AW and W, holds B/R responses under backpressure, resets memory deterministically and returns SLVERR for invalid addresses. The directed protocol test exercises different AW/W arrival orders, byte strobes, response stalls, 0x3FC boundary and invalid addresses. The scoreboard checks payload and response codes.

**Limits:** These passing scenarios do **not** establish exhaustive AXI4-Lite compliance. More reset-during-traffic, simultaneous read/write, throughput, random-seed regression, parameter-width and stress testing is needed. The coverage number is the testbench's custom functional coverage, not complete protocol coverage. The saved playground links above refer to the original implementation, not this revision.

Run the revised tests with a Questa-compatible simulator:

```bash
make run
make run_random
make run_protocol
```

## 📊 Statistics

- **Total Lines**: 945

- **RTL**: 139 lines

- **Testbench**: 806 lines

- **Files**: 12

## ⚙️ Features

✅ Full UVM architecture (driver, monitor, scoreboard, coverage)

✅ AXI4-Lite protocol-focused stimulus and checking (full compliance still requires broader verification)

✅ Write/Read transaction checking

✅ Basic OKAY response observation (SLVERR/error behavior not comprehensively verified)

✅ Functional coverage for addresses and operations

✅ Randomized sequences

## 📝 Note

This testbench uses SystemVerilog UVM. Verilator's UVM support is experimental - use commercial simulators (QuestaSim, Xcelium, VCS, Vivado) for production verification.
