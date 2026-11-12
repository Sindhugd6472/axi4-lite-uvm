// AXI4-Lite Testbench Top
module tb_top;
  
  import uvm_pkg::*;
  import axi_pkg::*;
  
  // Clock and reset
  logic clk;
  logic rst_n;
  
  // AXI Interface
  axi_if vif(clk, rst_n);
  
  // DUT - AXI Slave Memory
  axi_slave_mem dut (
    .clk(clk),
    .rst_n(rst_n),
    
    // Connect interface signals
    .awaddr(vif.awaddr),
    .awvalid(vif.awvalid),
    .awready(vif.awready),
    
    .wdata(vif.wdata),
    .wstrb(vif.wstrb),
    .wvalid(vif.wvalid),
    .wready(vif.wready),
    
    .bresp(vif.bresp),
    .bvalid(vif.bvalid),
    .bready(vif.bready),
    
    .araddr(vif.araddr),
    .arvalid(vif.arvalid),
    .arready(vif.arready),
    
    .rdata(vif.rdata),
    .rresp(vif.rresp),
    .rvalid(vif.rvalid),
    .rready(vif.rready)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end
  
  // Select a test with +UVM_TESTNAME=<name>; default to normal write/read.
  // Reset timing and test selection share one value to avoid mismatches.
  initial begin : test_and_reset
    string test_name;
    if (!$value$plusargs("UVM_TESTNAME=%s", test_name))
      test_name = "axi_write_read_test";

    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);

    fork
      begin : reset_generation
        rst_n = 0;
        repeat (5) @(negedge clk);
        rst_n = 1;

        // Only the dedicated reset test interrupts an outstanding response.
        if (test_name == "axi_reset_test") begin
          repeat (10) @(negedge clk);
          rst_n = 0;
          repeat (3) @(negedge clk);
          rst_n = 1;
        end
      end
      begin : uvm_test
        run_test(test_name);
      end
    join
  end
  
  // Timeout watchdog
  initial begin
    #10ms;
    $fatal(1, "TIMEOUT: UVM test did not complete");
  end
  
  // Waveform dump
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule
