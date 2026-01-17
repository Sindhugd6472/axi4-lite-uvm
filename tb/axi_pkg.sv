// AXI4-Lite UVM Package
package axi_pkg;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // Include all UVM files
  `include "axi_transaction.sv"
  `include "axi_master_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_agent.sv"
  `include "axi_scoreboard.sv"
  `include "axi_coverage.sv"
  `include "axi_env.sv"
  `include "axi_sequences.sv"
  `include "axi_test.sv"
  
endpackage
