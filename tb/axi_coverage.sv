// AXI4-Lite Functional Coverage
class axi_coverage extends uvm_subscriber #(axi_transaction);
  
  `uvm_component_utils(axi_coverage)
  
  // Coverage groups
  covergroup transaction_cg;
    
    // Transaction type coverage
    trans_type_cp: coverpoint trans.trans_type {
      bins write = {axi_transaction::WRITE};
      bins read = {axi_transaction::READ};
    }
    
    // Address coverage - sample different regions
    addr_cp: coverpoint trans.addr[31:0] {
      bins low_addr = {[32'h0000_0000:32'h0000_00FF]};
      bins mid_addr = {[32'h0000_0100:32'h0000_01FF]};
      bins high_addr = {[32'h0000_0200:32'h0000_03FF]};
    }
    
    // Write strobe coverage
    strb_cp: coverpoint trans.strb {
      bins byte_write = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins half_word = {4'b0011, 4'b1100};
      bins word = {4'b1111};
    }
    
    // Data patterns
    data_cp: coverpoint trans.data {
      bins zeros = {32'h0000_0000};
      bins ones = {32'hFFFF_FFFF};
      bins pattern_a5 = {32'hA5A5_A5A5};
      bins pattern_5a = {32'h5A5A_5A5A};
      bins other = default;
    }
    
    // Response coverage
    resp_cp: coverpoint trans.resp {
      bins okay = {2'b00};
      bins error = {2'b10};
    }
    
    // Cross coverage: transaction type with address
    type_addr_cross: cross trans_type_cp, addr_cp;
    
    // Cross coverage: write type with strobe
    write_strb_cross: cross trans_type_cp, strb_cp {
      ignore_bins read_strb = binsof(trans_type_cp.read);
    }
    
  endgroup
  
  axi_transaction trans;
  
  function new(string name = "axi_coverage", uvm_component parent = null);
    super.new(name, parent);
    transaction_cg = new();
  endfunction
  
  function void write(axi_transaction t);
    trans = t;
    transaction_cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), 
              $sformatf("Coverage = %.2f%%", transaction_cg.get_coverage()), UVM_NONE)
  endfunction
  
endclass
