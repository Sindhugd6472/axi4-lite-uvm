// AXI4-Lite master driver. All handshakes sampled on the clocking block.
class axi_master_driver extends uvm_driver #(axi_transaction);
  `uvm_component_utils(axi_master_driver)
  virtual axi_if vif;

  function new(string name="axi_master_driver", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"Virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    reset_signals();
    wait (vif.rst_n === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      if (req.trans_type == axi_transaction::WRITE)
        drive_write(req);
      else
        drive_read(req);
      seq_item_port.item_done();
    end
  endtask

  task reset_signals();
    @(vif.master_cb);
    vif.master_cb.awaddr <= '0;
    vif.master_cb.awvalid <= 0;
    vif.master_cb.wdata <= '0;
    vif.master_cb.wstrb <= 0;
    vif.master_cb.wvalid <= 0;
    vif.master_cb.bready <= 0;
    vif.master_cb.araddr <= '0;
    vif.master_cb.arvalid <= 0;
    vif.master_cb.rready <= 0;
  endtask

  task drive_write(axi_transaction tr);
    `uvm_info(get_type_name(),$sformatf("Driving WRITE: %s",tr.convert2string()),UVM_MEDIUM)
    fork
      begin : address_thread
        repeat (tr.awready_delay) @(vif.master_cb);
        @(vif.master_cb);
        vif.master_cb.awaddr <= tr.addr;
        vif.master_cb.awvalid <= 1;
        do @(vif.master_cb); while (!vif.master_cb.awready);
        vif.master_cb.awvalid <= 0;
      end
      begin : data_thread
        repeat (tr.wready_delay) @(vif.master_cb);
        @(vif.master_cb);
        vif.master_cb.wdata <= tr.data;
        vif.master_cb.wstrb <= tr.strb;
        vif.master_cb.wvalid <= 1;
        do @(vif.master_cb); while (!vif.master_cb.wready);
        vif.master_cb.wvalid <= 0;
      end
    join
    repeat (tr.bvalid_delay) @(vif.master_cb);
    vif.master_cb.bready <= 1;
    do @(vif.master_cb); while (!vif.master_cb.bvalid);
    tr.resp = vif.master_cb.bresp;
    vif.master_cb.bready <= 0;
    `uvm_info(get_type_name(),$sformatf("WRITE completed with resp=%0d",tr.resp),UVM_MEDIUM)
  endtask

  task drive_read(axi_transaction tr);
    `uvm_info(get_type_name(),$sformatf("Driving READ: %s",tr.convert2string()),UVM_MEDIUM)
    @(vif.master_cb);
    vif.master_cb.araddr <= tr.addr;
    vif.master_cb.arvalid <= 1;
    do @(vif.master_cb); while (!vif.master_cb.arready);
    vif.master_cb.arvalid <= 0;

    repeat (tr.bvalid_delay) @(vif.master_cb);
    vif.master_cb.rready <= 1;
    do @(vif.master_cb); while (!vif.master_cb.rvalid);
    tr.rdata = vif.master_cb.rdata;
    tr.resp = vif.master_cb.rresp;
    vif.master_cb.rready <= 0;
    `uvm_info(get_type_name(),$sformatf("READ completed: data=0x%0h resp=%0d",tr.rdata,tr.resp),UVM_MEDIUM)
  endtask
endclass
