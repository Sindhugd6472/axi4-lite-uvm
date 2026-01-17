// AXI4-Lite Scoreboard - Memory Model
class axi_scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(axi_scoreboard)
  
  uvm_analysis_imp #(axi_transaction, axi_scoreboard) item_collected_export;
  
  // Expected memory model
  bit [31:0] mem [bit[31:0]];
  
  // Statistics
  int write_count;
  int read_count;
  int match_count;
  int mismatch_count;
  
  function new(string name = "axi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_collected_export = new("item_collected_export", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write_count = 0;
    read_count = 0;
    match_count = 0;
    mismatch_count = 0;
  endfunction
  
  // Analyze transactions from monitor
  function void write(axi_transaction tr);
    if (tr.trans_type == axi_transaction::WRITE) begin
      process_write(tr);
    end else begin
      process_read(tr);
    end
  endfunction
  
  // Process write transaction
  function void process_write(axi_transaction tr);
    bit [31:0] addr_aligned;
    addr_aligned = {tr.addr[31:2], 2'b00};  // Word-aligned
    
    // Update expected memory based on strobes
    if (!mem.exists(addr_aligned))
      mem[addr_aligned] = 32'h0;
    
    for (int i = 0; i < 4; i++) begin
      if (tr.strb[i])
        mem[addr_aligned][i*8 +: 8] = tr.data[i*8 +: 8];
    end
    
    write_count++;
    `uvm_info(get_type_name(), 
              $sformatf("WRITE: Addr=0x%0h Data=0x%0h Strb=%4b - Updated memory model", 
                        addr_aligned, tr.data, tr.strb), UVM_MEDIUM)
  endfunction
  
  // Process read transaction and check
  function void process_read(axi_transaction tr);
    bit [31:0] addr_aligned;
    bit [31:0] expected_data;
    
    addr_aligned = {tr.addr[31:2], 2'b00};
    read_count++;
    
    // Get expected data
    if (mem.exists(addr_aligned)) begin
      expected_data = mem[addr_aligned];
    end else begin
      expected_data = 32'h0;  // Unwritten locations return 0
    end
    
    // Compare
    if (tr.rdata === expected_data) begin
      match_count++;
      `uvm_info(get_type_name(), 
                $sformatf("READ MATCH: Addr=0x%0h Expected=0x%0h Actual=0x%0h", 
                          addr_aligned, expected_data, tr.rdata), UVM_MEDIUM)
    end else begin
      mismatch_count++;
      `uvm_error(get_type_name(), 
                 $sformatf("READ MISMATCH: Addr=0x%0h Expected=0x%0h Actual=0x%0h", 
                           addr_aligned, expected_data, tr.rdata))
    end
  endfunction
  
  // Report statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "=== SCOREBOARD REPORT ===", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Writes: %0d", write_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Reads: %0d", read_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Matches: %0d", match_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("Mismatches: %0d", mismatch_count), UVM_NONE)
    
    if (mismatch_count > 0)
      `uvm_error(get_type_name(), "TEST FAILED: Data mismatches detected!")
    else if (read_count > 0)
      `uvm_info(get_type_name(), "TEST PASSED: All reads matched!", UVM_NONE)
  endfunction
  
endclass
