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
  input  logic [3:0] wstrb,
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

  // Memory array
  logic [DATA_WIDTH-1:0] mem [MEM_DEPTH];
  
  // Internal registers
  logic [ADDR_WIDTH-1:0] wr_addr;
  logic [ADDR_WIDTH-1:0] rd_addr;
  
  // Response codes
  localparam RESP_OKAY = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  
  //--------------------
  // Write Address Channel
  //--------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      awready <= 1'b0;
      wr_addr <= '0;
    end else begin
      if (awvalid && !awready) begin
        awready <= 1'b1;
        wr_addr <= awaddr;
      end else begin
        awready <= 1'b0;
      end
    end
  end
  
  //--------------------
  // Write Data Channel
  //--------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wready <= 1'b0;
    end else begin
      if (wvalid && !wready) begin
        wready <= 1'b1;
        // Write data to memory with byte enables
        for (int i = 0; i < 4; i++) begin
          if (wstrb[i])
            mem[wr_addr[9:2]][i*8 +: 8] <= wdata[i*8 +: 8];
        end
      end else begin
        wready <= 1'b0;
      end
    end
  end
  
  //--------------------
  // Write Response Channel
  //--------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bvalid <= 1'b0;
      bresp <= RESP_OKAY;
    end else begin
      if (wready && wvalid && !bvalid) begin
        bvalid <= 1'b1;
        bresp <= RESP_OKAY;
      end else if (bvalid && bready) begin
        bvalid <= 1'b0;
      end
    end
  end
  
  //--------------------
  // Read Address Channel
  //--------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready <= 1'b0;
      rd_addr <= '0;
    end else begin
      if (arvalid && !arready) begin
        arready <= 1'b1;
        rd_addr <= araddr;
      end else begin
        arready <= 1'b0;
      end
    end
  end
  
  //--------------------
  // Read Data Channel
  //--------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rvalid <= 1'b0;
      rdata <= '0;
      rresp <= RESP_OKAY;
    end else begin
      if (arready && arvalid && !rvalid) begin
        rvalid <= 1'b1;
        rdata <= mem[rd_addr[9:2]];
        rresp <= RESP_OKAY;
      end else if (rvalid && rready) begin
        rvalid <= 1'b0;
      end
    end
  end

endmodule
