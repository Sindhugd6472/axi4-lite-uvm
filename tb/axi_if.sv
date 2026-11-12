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
  
  // VALID and payload must remain stable while backpressured.
  property hold_valid(valid, ready, payload);
    @(posedge clk) disable iff (!rst_n)
    (valid && !ready) |=> (valid && $stable(payload));
  endproperty

  aw_hold: assert property (hold_valid(awvalid,awready,awaddr))
    else $fatal(1,"AW payload/VALID changed while stalled");
  w_hold: assert property (hold_valid(wvalid,wready,{wdata,wstrb}))
    else $fatal(1,"W payload/VALID changed while stalled");
  ar_hold: assert property (hold_valid(arvalid,arready,araddr))
    else $fatal(1,"AR payload/VALID changed while stalled");
  b_hold: assert property (hold_valid(bvalid,bready,bresp))
    else $fatal(1,"B response/VALID changed while stalled");
  r_hold: assert property (hold_valid(rvalid,rready,{rdata,rresp}))
    else $fatal(1,"R response/VALID changed while stalled");

endinterface
