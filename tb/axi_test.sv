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
    if (!seq.randomize())
      `uvm_fatal(get_type_name(), "Sequence randomization failed")
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
  
endclass

// Directed independent-channel and backpressure test.
class axi_protocol_test extends axi_base_test;
  `uvm_component_utils(axi_protocol_test)
  function new(string name="axi_protocol_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    axi_protocol_seq seq;
    phase.raise_objection(this);
    seq=axi_protocol_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100ns;
    phase.drop_objection(this);
  endtask
endclass


// Reset an outstanding write response, then prove normal traffic recovers.
class axi_reset_test extends axi_base_test;
  `uvm_component_utils(axi_reset_test)

  function new(string name = "axi_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_reset_seq seq;
    axi_write_read_seq recovery_seq;
    phase.raise_objection(this);

    wait (env.agent.driver.vif.rst_n === 1'b1);
    repeat (4) @(posedge env.agent.driver.vif.clk);
    seq = axi_reset_seq::type_id::create("seq");
    fork
      seq.start(env.agent.sequencer);
    join_none

    // Second reset in tb_top begins at 150 ns.
    repeat (6) @(negedge env.agent.driver.vif.clk);
    if (env.agent.driver.vif.bvalid !== 1'b1 ||
        env.agent.driver.vif.bready !== 1'b0)
      `uvm_error("RESET_TEST", "FAIL: Write response not stalled at 140 ns")
    else
      `uvm_info("RESET_TEST", "PASS: Write response stalled at 140 ns", UVM_LOW)

    #9ns;
    if (env.agent.driver.vif.bvalid !== 1'b1 ||
        env.agent.driver.vif.bready !== 1'b0)
      `uvm_error("RESET_TEST", "FAIL: No stalled response at 149 ns")
    else
      `uvm_info("RESET_TEST", "PASS: BVALID=1 BREADY=0 at 149 ns", UVM_LOW)

    @(negedge env.agent.driver.vif.rst_n);
    #1ns;
    if (env.agent.driver.vif.awready !== 1'b0 ||
        env.agent.driver.vif.wready !== 1'b0 ||
        env.agent.driver.vif.bvalid !== 1'b0 ||
        env.agent.driver.vif.rvalid !== 1'b0)
      `uvm_error("RESET_TEST", "FAIL: Pending responses not cleared")
    else
      `uvm_info("RESET_TEST", "PASS: Reset cleared pending responses", UVM_LOW)

    @(posedge env.agent.driver.vif.rst_n);
    repeat (3) @(posedge env.agent.driver.vif.clk);
    if (env.agent.driver.vif.bvalid !== 1'b0)
      `uvm_error("RESET_TEST", "FAIL: Stale write response after reset")
    else
      `uvm_info("RESET_TEST", "PASS: No stale response after reset", UVM_LOW)

    recovery_seq = axi_write_read_seq::type_id::create("recovery_seq");
    `uvm_info("RESET_TEST", "Starting post-reset recovery sequence", UVM_LOW)
    recovery_seq.start(env.agent.sequencer);
    `uvm_info("RESET_TEST", "Post-reset recovery sequence completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
