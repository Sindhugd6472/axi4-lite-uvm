// AXI4-Lite Monitor
class axi_monitor extends uvm_monitor;
  
  `uvm_component_utils(axi_monitor)
  
  virtual axi_if vif;
  uvm_analysis_port #(axi_transaction) item_collected_port;
  
  function new(string name = "axi_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface not found!")
  endfunction
  
  task run_phase(uvm_phase phase);
    fork
      monitor_write();
      monitor_read();
    join_none
  endtask
  
  // Monitor Write Transactions
  task monitor_write();
    axi_transaction tr;
    bit [31:0] addresses[$], data[$];
    bit [3:0] strobes[$];
    forever begin
      @(vif.monitor_cb);
      if (!vif.rst_n) begin
        addresses.delete(); data.delete(); strobes.delete();
      end else begin
        // AW and W are independent and can arrive in either order.
        if (vif.monitor_cb.awvalid && vif.monitor_cb.awready)
          addresses.push_back(vif.monitor_cb.awaddr);
        if (vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin
          data.push_back(vif.monitor_cb.wdata);
          strobes.push_back(vif.monitor_cb.wstrb);
        end
        if (vif.monitor_cb.bvalid && vif.monitor_cb.bready) begin
          if (addresses.size() == 0 || data.size() == 0)
            `uvm_fatal(get_type_name(), "Write response without address/data handshake")
          tr = axi_transaction::type_id::create("tr");
          tr.trans_type = axi_transaction::WRITE;
          tr.addr = addresses.pop_front();
          tr.data = data.pop_front(); tr.strb = strobes.pop_front();
          tr.resp = vif.monitor_cb.bresp;
          item_collected_port.write(tr);
        end
      end
    end
  endtask

  // Monitor Read Transactions
  task monitor_read();
    axi_transaction tr;
    bit [31:0] addr, rdata;
    bit [1:0] resp;
    
    forever begin
      // Wait for read address handshake
      @(vif.monitor_cb);
      if (vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
        addr = vif.monitor_cb.araddr;
        
        // Wait for read data handshake
        while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready))
          @(vif.monitor_cb);
        rdata = vif.monitor_cb.rdata;
        resp = vif.monitor_cb.rresp;
        
        // Create transaction and broadcast
        tr = axi_transaction::type_id::create("tr");
        tr.trans_type = axi_transaction::READ;
        tr.addr = addr;
        tr.rdata = rdata;
        tr.resp = resp;
        
        `uvm_info(get_type_name(), $sformatf("Monitored READ: %s", tr.convert2string()), UVM_HIGH)
        item_collected_port.write(tr);
      end
    end
  endtask
  
endclass
