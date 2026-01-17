// AXI4-Lite Base Sequence
class axi_base_sequence extends uvm_sequence #(axi_transaction);
  
  `uvm_object_utils(axi_base_sequence)
  
  function new(string name = "axi_base_sequence");
    super.new(name);
  endfunction
  
endclass

// Simple Write-Read Sequence
class axi_write_read_seq extends axi_base_sequence;
  
  `uvm_object_utils(axi_write_read_seq)
  
  function new(string name = "axi_write_read_seq");
    super.new(name);
  endfunction
  
  task body();
    axi_transaction tr;
    
    // Write some data
    repeat(10) begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {trans_type == WRITE;});
      finish_item(tr);
    end
    
    // Read back the data
    repeat(10) begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {trans_type == READ;});
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
      assert(tr.randomize());
      finish_item(tr);
    end
  endtask
  
endclass
