// AXI4-Lite Transaction Class
class axi_transaction extends uvm_sequence_item;
  
  // Transaction type
  typedef enum {READ, WRITE} trans_type_e;
  rand trans_type_e trans_type;
  
  // Address and data
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [3:0]  strb;  // Write strobes (which bytes to write)
  
  // Response
  bit [1:0] resp;  // Captured from slave
  bit [31:0] rdata; // Read data from slave
  
  // Timing controls
  rand int awready_delay;  // Cycles before slave accepts address
  rand int wready_delay;   // Cycles before slave accepts data
  rand int bvalid_delay;   // Cycles before slave responds
  
  // Constraints
  constraint addr_align_c {
    addr[1:0] == 2'b00;  // 32-bit aligned addresses
  }
  
  constraint reasonable_delays_c {
    awready_delay inside {[0:5]};
    wready_delay inside {[0:5]};
    bvalid_delay inside {[0:5]};
  }
  
  constraint valid_strb_c {
    strb inside {4'b0001, 4'b0011, 4'b1111};  // Byte, half-word, word
  }
  
  // UVM automation macros
  `uvm_object_utils_begin(axi_transaction)
    `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(strb, UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end
  
  // Constructor
  function new(string name = "axi_transaction");
    super.new(name);
  endfunction
  
  // Convert to string for printing
  function string convert2string();
    string s;
    s = $sformatf("Type=%s Addr=0x%0h", trans_type.name(), addr);
    if (trans_type == WRITE)
      s = {s, $sformatf(" Data=0x%0h Strb=%4b", data, strb)};
    else
      s = {s, $sformatf(" RData=0x%0h", rdata)};
    s = {s, $sformatf(" Resp=%0d", resp)};
    return s;
  endfunction
  
endclass
