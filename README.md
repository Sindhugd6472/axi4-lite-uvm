# AXI4-Lite UVM Verification Environment

A SystemVerilog/UVM verification environment for a **32-bit AXI4-Lite slave memory**. The project includes a synthesizable-style RTL model, reusable UVM components, directed and randomized stimulus, a reference-memory scoreboard, functional coverage, and a reset-during-traffic recovery test.

**Verification status:** Four UVM tests passed in **Siemens Questa 2025.2 / UVM 1.2** on EDA Playground (November 12, 2026). All final runs reported zero UVM errors, zero fatal errors, zero scoreboard mismatches, and zero response-code mismatches. These results cover the scenarios exercised, **not exhaustive AXI4-Lite compliance**.

## Features

- **AXI4-Lite memory slave:** independent AW/W buffering, one outstanding write response and one outstanding read response; BVALID/RVALID remain asserted until accepted.
- **Access handling:** 32-bit aligned reads and byte-strobe writes, including partial-word updates; OKAY for supported addresses and SLVERR for invalid or unaligned addresses.
- **UVM verification:** master driver, monitor, agent, sequencer, reusable sequences, environment, scoreboard, and transaction-level functional coverage.
- **Reset verification:** cancels an outstanding write response, checks that reset clears pending outputs, checks for stale responses, and verifies post-reset read/write recovery.
- **Test selection:** a dedicated second reset pulse is generated **only** for `axi_reset_test`. Other tests use the startup reset.

## Project structure

```text
axi4-lite-uvm/
├── rtl/
│   └── axi_slave_mem.sv       # AXI4-Lite memory RTL
├── tb/
│   ├── axi_if.sv              # Interface and clocking blocks
│   ├── axi_transaction.sv     # Sequence item
│   ├── axi_master_driver.sv   # AXI master driver with reset cancellation
│   ├── axi_monitor.sv         # Bus transaction monitor
│   ├── axi_agent.sv           # Agent and sequencer
│   ├── axi_scoreboard.sv      # Memory model, data and response checks
│   ├── axi_coverage.sv        # Functional covergroup
│   ├── axi_env.sv             # UVM environment
│   ├── axi_sequences.sv       # Directed, random, protocol, reset sequences
│   ├── axi_test.sv            # Four registered UVM tests
│   ├── axi_pkg.sv             # UVM package
│   └── tb_top.sv              # DUT wiring, clock, reset, test selection
├── Makefile
├── README.md
└── LICENSE
```

## Final simulation results

Tested with **Siemens Questa 2025.2, UVM 1.2**, in EDA Playground on **November 12, 2026**, after the reset-selection update (commit `5943cbf`).

| Test | Completed writes | Completed reads | Read matches | Scoreboard mismatches | UVM warnings | UVM errors / fatals | Functional coverage |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `axi_write_read_test` | 10 | 10 | 10/10 | 0 | 0 | 0 / 0 | 82.14% |
| `axi_random_test` | 19 | 20 | 20/20 | 0 | 0 | 0 / 0 | 82.14% |
| `axi_protocol_test` | 7 | 7 | 7/7 | 0 | 0 | 0 / 0 | 73.81% |
| `axi_reset_test` | 10 | 10 | 10/10 | 0 | 1 (expected) | 0 / 0 | 82.14% |

All four runs also reported **zero response-code mismatches**. The reset-test UVM warning is intentional: the driver cancels an in-flight write when reset is asserted. Questa additionally printed a nonfatal optimization warning for the `+acc` switch.

The protocol test includes partial writes, boundary accesses, error responses for invalid/unaligned addresses, and readback checking. The reset test checks a stalled B response at **140 ns and 149 ns**, reset at **150 ns**, clearing of pending responses, no stale response after reset, and subsequent successful write/read traffic.

**Evidence:** [Reset-test EDA Playground example](https://www.edaplayground.com/x/8LD2) · [Merged verification PR #3 with final regression results](https://github.com/Sindhugd6472/axi4-lite-uvm/pull/3).

> The linked saved reset playground was created before the final test-selection refinement. The final four-test figures above come from the separately executed EDA Playground logs after that update, documented in PR #3. Earlier playground examples: [write/read](https://www.edaplayground.com/x/9BXQ), [random](https://www.edaplayground.com/x/haFZ); these are not the final revision.

## Running the tests

### Questa/ModelSim with UVM support

Requires a simulator installation with `vlib`, `vlog`, `vsim`, and UVM on the PATH. The Makefile compiles the RTL, interface, UVM package, and top module.

```bash
make run                            # default: axi_write_read_test
make run_random                     # axi_random_test
make run_protocol                   # axi_protocol_test
make run UVM_TEST=axi_reset_test    # reset during traffic and recovery
```

The `make` flow is provided for local use but **has not been separately executed and validated** here. The verified results above are from EDA Playground, and the repository does not currently run commercial UVM simulations in GitHub Actions.

### EDA Playground

1. Choose **SystemVerilog**, **UVM 1.2**, and **Siemens Questa 2025.2**.
2. Put `rtl/axi_slave_mem.sv` in `design.sv`.
3. In `testbench.sv`, include `axi_if.sv`, define `axi_pkg` with the UVM class includes in the order shown in `tb/axi_pkg.sv`, and include `tb_top.sv` after `endpackage`. Keep the included class/interface/top files as separate tabs.
4. In **Run Options**, select the test with `+UVM_TESTNAME=axi_reset_test` (or `axi_write_read_test`, `axi_random_test`, `axi_protocol_test`). The testbench defaults to write/read if no test name is supplied.
5. Run and inspect the UVM report summary and scoreboard results.

## Verification scope and limitations

- The reported functional coverage is from the included covergroup (transaction type, address regions, strobes, data patterns, responses, and crosses). It is **not** a complete AXI4-Lite protocol coverage or sign-off metric.
- The implementation targets a **single-outstanding, 32-bit memory slave** with default memory depth 256, not a general-purpose AXI4-Lite IP.
- Directed and random tests exercise representative channel timing, data, error responses, and reset behavior, but do not exhaustively test all channel interleavings, simultaneous read/write load, long stalls, randomized seeds, parameter configurations, or throughput limits.
- Random reads of unwritten memory legitimately return zero because the DUT initializes memory to zero.
- Alternative simulator flows (such as VCS or Xcelium) and the local Makefile have not been independently validated.

## License

MIT. See [LICENSE](LICENSE).
