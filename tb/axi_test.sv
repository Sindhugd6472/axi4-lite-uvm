// AXI4-Lite Base Test
class axi_base_test extends uvm_test;
  
  `uvm_component_utils(axi_base_test)
  
  axi_env env;
  
  function new(string name = "axi_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::type_id::create("env", this);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #100ns;
    phase.drop_objection(this);
  endtask
  
endclass

// Write-Read Test
class axi_write_read_test extends axi_base_test;
  
  `uvm_component_utils(axi_write_read_test)
  
  function new(string name = "axi_write_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    axi_write_read_seq seq;
    
    phase.raise_objection(this);
    seq = axi_write_read_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
  
endclass

// Random Test
class axi_random_test extends axi_base_test;
  
  `uvm_component_utils(axi_random_test)
  
  function new(string name = "axi_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    axi_random_seq seq;
    
    phase.raise_objection(this);
    seq = axi_random_seq::type_id::create("seq");
    assert(seq.randomize());
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
  
endclass
