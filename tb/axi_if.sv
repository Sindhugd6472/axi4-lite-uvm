// AXI4-Lite Interface with Protocol Assertions
interface axi_if(input logic clk, input logic rst_n);
  
  // Write Address Channel
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;
  
  // Write Data Channel
  logic [31:0] wdata;
  logic [3:0]  wstrb;   // Write strobes (byte enables)
  logic        wvalid;
  logic        wready;
  
  // Write Response Channel
  logic [1:0]  bresp;   // 00=OKAY, 01=EXOKAY, 10=SLVERR, 11=DECERR
  logic        bvalid;
  logic        bready;
  
  // Read Address Channel
  logic [31:0] araddr;
  logic        arvalid;
  logic        arready;
  
  // Read Data Channel
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;
  
  // Clocking block for master driver
  clocking master_cb @(posedge clk);
    default input #1 output #1;
    output awaddr, awvalid, wdata, wstrb, wvalid, bready;
    output araddr, arvalid, rready;
    input  awready, wready, bresp, bvalid;
    input  arready, rdata, rresp, rvalid;
  endclocking
  
  // Clocking block for monitor
  clocking monitor_cb @(posedge clk);
    default input #1;
    input awaddr, awvalid, awready;
    input wdata, wstrb, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arvalid, arready;
    input rdata, rresp, rvalid, rready;
  endclocking
  
  // Modports
  modport master(clocking master_cb, input clk, rst_n);
  modport monitor(clocking monitor_cb, input clk, rst_n);
  
  // Basic Protocol Assertions
  // Rule: VALID must not depend on READY
  property valid_stable(valid, ready);
    @(posedge clk) disable iff(!rst_n)
    (valid && !ready) |=> valid;
  endproperty
  
  aw_valid_stable: assert property(valid_stable(awvalid, awready))
    else $error("AWVALID deasserted before AWREADY");
    
  w_valid_stable: assert property(valid_stable(wvalid, wready))
    else $error("WVALID deasserted before WREADY");
    
  ar_valid_stable: assert property(valid_stable(arvalid, arready))
    else $error("ARVALID deasserted before ARREADY");
  
endinterface
