// AXI4-Lite UVM Environment
class axi_env extends uvm_env;
  
  `uvm_component_utils(axi_env)
  
  axi_agent agent;
  axi_scoreboard scoreboard;
  axi_coverage coverage;
  
  function new(string name = "axi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agent = axi_agent::type_id::create("agent", this);
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    coverage = axi_coverage::type_id::create("coverage", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor to scoreboard and coverage
    agent.monitor.item_collected_port.connect(scoreboard.item_collected_export);
    agent.monitor.item_collected_port.connect(coverage.analysis_export);
  endfunction
  
endclass
