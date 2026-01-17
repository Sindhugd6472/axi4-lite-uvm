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
  
  // Reset generation
  initial begin
    rst_n = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
  end
  
  // UVM test flow
  initial begin
    // Pass interface to UVM
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
    
    // Run test
    run_test();
  end
  
  // Timeout watchdog
  initial begin
    #10ms;
    $display("TIMEOUT: Test did not complete!");
    $finish;
  end
  
  // Waveform dump
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule
