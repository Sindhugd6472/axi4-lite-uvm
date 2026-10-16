`timescale 1ns/1ps
module axi_rtl_tb;
  logic clk=0; always #5 clk=~clk;
  logic rst_n=0;
  logic [31:0] awaddr=0,wdata=0,araddr=0,rdata;
  logic [3:0] wstrb=0;
  logic awvalid=0,awready,wvalid=0,wready,bvalid,bready=0;
  logic arvalid=0,arready,rvalid,rready=0;
  logic [1:0] bresp,rresp;
  axi_slave_mem dut(.*);
  task automatic send_aw(input logic [31:0] a);
    @(negedge clk); awvalid=1;awaddr=a;
    do @(posedge clk); while (!awready);
    @(negedge clk);awvalid=0;
  endtask
  task automatic send_w(input logic [31:0] d,input logic [3:0] s);
    @(negedge clk);wvalid=1;wdata=d;wstrb=s;
    do @(posedge clk); while (!wready);
    @(negedge clk);wvalid=0;
  endtask
  task automatic response(input logic [1:0] expected);
    wait(bvalid); @(negedge clk);
    repeat(3) begin
      if (!bvalid || bresp !== expected) $fatal(1,"Write response/backpressure failure");
      @(negedge clk);
    end
    bready=1; @(negedge clk); bready=0;
  endtask
  task automatic read_word(input logic [31:0] a,input logic [31:0] d,input logic [1:0] resp);
    @(negedge clk); araddr=a; arvalid=1;
    do @(posedge clk); while(!arready);
    @(negedge clk); arvalid=0;
    wait(rvalid);
    repeat(3) begin
      if (!rvalid || rdata !== d || rresp !== resp) $fatal(1,"Read data/response/backpressure failure addr=%h data=%h",a,rdata);
      @(negedge clk);
    end
    rready=1; @(negedge clk); rready=0;
  endtask
  initial begin
    repeat(2) @(negedge clk);rst_n=1;
    read_word(0,0,0);
    // Data before address, then address before data, then simultaneous.
    send_w('h12345678,15);repeat(3) @(negedge clk);send_aw(4);response(0);
    read_word(4,'h12345678,0);
    send_aw(8);repeat(3) @(negedge clk);send_w('hdeadbeef,15);response(0);
    read_word(8,'hdeadbeef,0);
    fork send_aw(4); send_w('haabbccdd,3); join
    response(0);read_word(4,'h1234ccdd,0);
    fork send_aw(1024); send_w('hffffffff,15); join
    response(2);read_word(1024,0,2);read_word(0,0,0);
    $display("PASS: AXI independent channels, strobes, backpressure, reset and invalid addresses");
    $finish;
  end
  initial begin #100000; $fatal(1,"Timeout"); end
endmodule
