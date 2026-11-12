// AXI4-Lite single-outstanding 32-bit memory slave.
// AW and W are independently buffered. B/R responses remain valid until accepted.
module axi_slave_mem #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter MEM_DEPTH = 256
)(
  input logic clk, rst_n,
  input logic [ADDR_WIDTH-1:0] awaddr,
  input logic awvalid,
  output logic awready,
  input logic [DATA_WIDTH-1:0] wdata,
  input logic [3:0] wstrb,
  input logic wvalid,
  output logic wready,
  output logic [1:0] bresp,
  output logic bvalid,
  input logic bready,
  input logic [ADDR_WIDTH-1:0] araddr,
  input logic arvalid,
  output logic arready,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic [1:0] rresp,
  output logic rvalid,
  input logic rready
);
  localparam logic [1:0] RESP_OKAY = 2'b00;
  localparam logic [1:0] RESP_SLVERR = 2'b10;

  logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
  logic aw_pending, w_pending;
  logic [ADDR_WIDTH-1:0] saved_awaddr;
  logic [DATA_WIDTH-1:0] saved_wdata;
  logic [3:0] saved_wstrb;

  // Each channel can be accepted before the other, including with stalls.
  // Block a second write while the current response is outstanding.
  assign awready = rst_n && !aw_pending && !bvalid;
  assign wready  = rst_n && !w_pending  && !bvalid;
  assign arready = rst_n && !rvalid;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_pending <= 1'b0;
      w_pending <= 1'b0;
      saved_awaddr <= '0;
      saved_wdata <= '0;
      saved_wstrb <= '0;
      bvalid <= 1'b0;
      bresp <= RESP_OKAY;
      rvalid <= 1'b0;
      rdata <= '0;
      rresp <= RESP_OKAY;
      for (int i = 0; i < MEM_DEPTH; i++)
        mem[i] <= '0;
    end else begin
      if (awvalid && awready) begin
        saved_awaddr <= awaddr;
        aw_pending <= 1'b1;
      end
      if (wvalid && wready) begin
        saved_wdata <= wdata;
        saved_wstrb <= wstrb;
        w_pending <= 1'b1;
      end

      // Both buffered handshakes are required before writing.
      if (aw_pending && w_pending && !bvalid) begin
        if (saved_awaddr[1:0] != 2'b00 ||
            (saved_awaddr >> 2) >= MEM_DEPTH) begin
          bresp <= RESP_SLVERR;
        end else begin
          for (int i = 0; i < 4; i++)
            if (saved_wstrb[i])
              mem[saved_awaddr >> 2][8*i +: 8] <= saved_wdata[8*i +: 8];
          bresp <= RESP_OKAY;
        end
        aw_pending <= 1'b0;
        w_pending <= 1'b0;
        bvalid <= 1'b1;
      end else if (bvalid && bready) begin
        bvalid <= 1'b0;
      end

      // One outstanding read; hold payload stable under backpressure.
      if (arvalid && arready) begin
        if (araddr[1:0] != 2'b00 || (araddr >> 2) >= MEM_DEPTH) begin
          rdata <= '0;
          rresp <= RESP_SLVERR;
        end else begin
          rdata <= mem[araddr >> 2];
          rresp <= RESP_OKAY;
        end
        rvalid <= 1'b1;
      end else if (rvalid && rready) begin
        rvalid <= 1'b0;
      end
    end
  end
endmodule
