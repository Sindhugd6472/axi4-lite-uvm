// Simple AXI4-Lite Memory Slave
module axi_slave_mem #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter MEM_DEPTH = 256  // 256 words = 1KB
)(
  input  logic clk,
  input  logic rst_n,
  
  // Write Address Channel
  input  logic [ADDR_WIDTH-1:0] awaddr,
  input  logic awvalid,
  output logic awready,
  
  // Write Data Channel
  input  logic [DATA_WIDTH-1:0] wdata,
  input  logic [DATA_WIDTH/8-1:0] wstrb,
  input  logic wvalid,
  output logic wready,
  
  // Write Response Channel
  output logic [1:0] bresp,
  output logic bvalid,
  input  logic bready,
  
  // Read Address Channel
  input  logic [ADDR_WIDTH-1:0] araddr,
  input  logic arvalid,
  output logic arready,
  
  // Read Data Channel
  output logic [DATA_WIDTH-1:0] rdata,
  output logic [1:0] rresp,
  output logic rvalid,
  input  logic rready
);

  localparam BYTES = DATA_WIDTH/8;
  localparam ADDR_LSB = $clog2(BYTES);
  logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
  logic [ADDR_WIDTH-1:0] wr_addr;
  logic [DATA_WIDTH-1:0] wr_data;
  logic [BYTES-1:0] wr_strb;
  logic have_addr, have_data;
  assign awready = rst_n && !have_addr && !bvalid;
  assign wready = rst_n && !have_data && !bvalid;
  assign arready = rst_n && !rvalid;

  initial begin
    if (DATA_WIDTH < 8 || DATA_WIDTH % 8 || (BYTES & (BYTES-1)) || MEM_DEPTH < 1)
      $fatal(1, "Invalid memory geometry");
  end

  // Buffer independent AW and W handshakes; hold the response under backpressure.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      have_addr <= 0; have_data <= 0;
      wr_addr <= 0; wr_data <= 0; wr_strb <= 0;
      bvalid <= 0; bresp <= 0;
      rvalid <= 0; rresp <= 0; rdata <= 0;
      for (int i=0; i<MEM_DEPTH; i++) mem[i] <= '0;
    end else begin
      if (awvalid && awready) begin wr_addr <= awaddr; have_addr <= 1; end
      if (wvalid && wready) begin
        wr_data <= wdata; wr_strb <= wstrb; have_data <= 1;
      end
      if (have_addr && have_data && !bvalid) begin
        have_addr <= 0; have_data <= 0; bvalid <= 1;
        bresp <= ((wr_addr >> ADDR_LSB) < MEM_DEPTH) ? 2'b00 : 2'b10;
        if ((wr_addr >> ADDR_LSB) < MEM_DEPTH)
          for (int i=0; i<BYTES; i++)
            if (wr_strb[i]) mem[wr_addr >> ADDR_LSB][8*i +: 8] <= wr_data[8*i +: 8];
      end else if (bvalid && bready) bvalid <= 0;
      if (arvalid && arready) begin
        rvalid <= 1;
        rresp <= ((araddr >> ADDR_LSB) < MEM_DEPTH) ? 2'b00 : 2'b10;
        rdata <= ((araddr >> ADDR_LSB) < MEM_DEPTH) ? mem[araddr >> ADDR_LSB] : '0;
      end else if (rvalid && rready) rvalid <= 0;
    end
  end
endmodule
