// AXI4-Lite scoreboard with byte strobe and response-code checking.
class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)
  uvm_analysis_imp #(axi_transaction,axi_scoreboard) item_collected_export;
  bit [31:0] mem [bit[31:0]];
  int write_count,read_count,match_count,mismatch_count,response_error_count;
  function new(string name="axi_scoreboard",uvm_component parent=null);
    super.new(name,parent);
    item_collected_export=new("item_collected_export",this);
  endfunction

  virtual axi_if vif;

  task run_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface not found")
    forever begin
      @(negedge vif.rst_n);
      mem.delete();
      `uvm_info("AXI_RESET", "Scoreboard memory cleared on reset", UVM_LOW)
    end
  endtask

  function bit invalid_addr(bit [31:0] addr);
    return (addr[1:0] != 0 || addr > 32'h0000_03FC);
  endfunction

  function void write(axi_transaction tr);
    bit [31:0] aligned_addr,expected_data;
    bit [1:0] expected_resp;
    aligned_addr={tr.addr[31:2],2'b00};
    expected_resp=invalid_addr(tr.addr) ? 2'b10 : 2'b00;
    if (tr.resp !== expected_resp) begin
      response_error_count++;
      `uvm_error(get_type_name(),$sformatf("RESPONSE MISMATCH: Addr=%h expected=%b actual=%b",tr.addr,expected_resp,tr.resp))
    end

    if (tr.trans_type == axi_transaction::WRITE) begin
      write_count++;
      if (!invalid_addr(tr.addr) && tr.resp==2'b00) begin
        if (!mem.exists(aligned_addr)) mem[aligned_addr]=0;
        for (int i=0;i<4;i++)
          if (tr.strb[i]) mem[aligned_addr][8*i +:8]=tr.data[8*i +:8];
      end
      `uvm_info(get_type_name(),$sformatf("WRITE addr=%h data=%h strb=%b resp=%b",tr.addr,tr.data,tr.strb,tr.resp),UVM_MEDIUM)
    end else begin
      read_count++;
      if (invalid_addr(tr.addr))
        expected_data=0;
      else if (mem.exists(aligned_addr))
        expected_data=mem[aligned_addr];
      else
        expected_data=0; // DUT resets every memory word to zero
      if (tr.rdata === expected_data) begin
        match_count++;
        `uvm_info(get_type_name(),$sformatf("READ MATCH addr=%h expected=%h actual=%h",tr.addr,expected_data,tr.rdata),UVM_MEDIUM)
      end else begin
        mismatch_count++;
        `uvm_error(get_type_name(),$sformatf("READ MISMATCH addr=%h expected=%h actual=%h",tr.addr,expected_data,tr.rdata))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),$sformatf("SCOREBOARD: Writes=%0d Reads=%0d Matches=%0d Mismatches=%0d ResponseErrors=%0d",write_count,read_count,match_count,mismatch_count,response_error_count),UVM_NONE)
    if (mismatch_count || response_error_count || !read_count || !write_count)
      `uvm_error(get_type_name(),"TEST FAILED: scoreboard mismatch, response error, or missing read/write traffic")
    else
      `uvm_info(get_type_name(),"TEST PASSED: scoreboard comparisons and responses matched",UVM_NONE)
  endfunction
endclass
