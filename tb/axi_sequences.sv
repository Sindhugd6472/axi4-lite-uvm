// AXI4-Lite Base Sequence
class axi_base_sequence extends uvm_sequence #(axi_transaction);
  
  `uvm_object_utils(axi_base_sequence)
  
  function new(string name = "axi_base_sequence");
    super.new(name);
  endfunction
  
endclass

// Write each randomized location, then read back the SAME locations.
// This checks the scoreboard against actual stored data instead of unrelated reads.
class axi_write_read_seq extends axi_base_sequence;
  `uvm_object_utils(axi_write_read_seq)

  function new(string name = "axi_write_read_seq");
    super.new(name);
  endfunction

  task body();
    axi_transaction tr;
    bit [31:0] addresses[$];
    bit [31:0] target_addr;
    repeat (10) begin
      tr = axi_transaction::type_id::create("write_tr");
      start_item(tr);
      if (!tr.randomize() with {trans_type == WRITE;})
        `uvm_fatal(get_type_name(), "WRITE randomization failed")
      addresses.push_back(tr.addr);
      finish_item(tr);
    end
    foreach (addresses[i]) begin
      target_addr = addresses[i];
      tr = axi_transaction::type_id::create("read_tr");
      start_item(tr);
      if (!tr.randomize() with {trans_type == READ; addr == local::target_addr;})
        `uvm_fatal(get_type_name(), "READ randomization failed")
      finish_item(tr);
    end
  endtask
endclass

// Random mixed sequence
class axi_random_seq extends axi_base_sequence;
  
  `uvm_object_utils(axi_random_seq)
  
  rand int num_trans;
  
  constraint reasonable_c {
    num_trans inside {[20:50]};
  }
  
  function new(string name = "axi_random_seq");
    super.new(name);
  endfunction
  
  task body();
    axi_transaction tr;
    
    repeat(num_trans) begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize())
        `uvm_fatal(get_type_name(), "Transaction randomization failed")
      finish_item(tr);
    end
  endtask
  
endclass
