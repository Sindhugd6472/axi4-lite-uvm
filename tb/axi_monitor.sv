// AXI4-Lite handshake monitor. AW and W may arrive in either order.
class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  virtual axi_if vif;
  uvm_analysis_port #(axi_transaction) item_collected_port;

  function new(string name="axi_monitor",uvm_component parent=null);
    super.new(name,parent);
    item_collected_port=new("item_collected_port",this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"Virtual interface not found")
  endfunction
  task run_phase(uvm_phase phase);
    fork
      monitor_write();
      monitor_read();
    join
  endtask

  task monitor_write();
    axi_transaction tr;
    bit got_aw,got_w;
    bit [31:0] saved_addr,saved_data;
    bit [3:0] saved_strb;
    got_aw=0;got_w=0;
    forever begin
      @(vif.monitor_cb);
      if (!vif.rst_n) begin
        got_aw=0;got_w=0;
      end else begin
        if (vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
          if (got_aw) `uvm_error(get_type_name(),"AW accepted before prior write response")
          saved_addr=vif.monitor_cb.awaddr;
          got_aw=1;
        end
        if (vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin
          if (got_w) `uvm_error(get_type_name(),"W accepted before prior write response")
          saved_data=vif.monitor_cb.wdata;
          saved_strb=vif.monitor_cb.wstrb;
          got_w=1;
        end
        if (vif.monitor_cb.bvalid && vif.monitor_cb.bready) begin
          if (!(got_aw && got_w))
            `uvm_error(get_type_name(),"Write response without both AW and W handshakes")
          else begin
            tr=axi_transaction::type_id::create("write_tr");
            tr.trans_type=axi_transaction::WRITE;
            tr.addr=saved_addr;
            tr.data=saved_data;
            tr.strb=saved_strb;
            tr.resp=vif.monitor_cb.bresp;
            item_collected_port.write(tr);
          end
          got_aw=0;got_w=0;
        end
      end
    end
  endtask

  task monitor_read();
    axi_transaction tr;
    bit got_ar;
    bit [31:0] saved_addr;
    got_ar=0;
    forever begin
      @(vif.monitor_cb);
      if (!vif.rst_n)
        got_ar=0;
      else begin
        if (vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
          if (got_ar) `uvm_error(get_type_name(),"Read address accepted before prior response")
          saved_addr=vif.monitor_cb.araddr;
          got_ar=1;
        end
        if (vif.monitor_cb.rvalid && vif.monitor_cb.rready) begin
          if (!got_ar)
            `uvm_error(get_type_name(),"Read response without address handshake")
          else begin
            tr=axi_transaction::type_id::create("read_tr");
            tr.trans_type=axi_transaction::READ;
            tr.addr=saved_addr;
            tr.rdata=vif.monitor_cb.rdata;
            tr.resp=vif.monitor_cb.rresp;
            item_collected_port.write(tr);
          end
          got_ar=0;
        end
      end
    end
  endtask
endclass
