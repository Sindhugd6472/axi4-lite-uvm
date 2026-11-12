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

// Directed protocol exercise: W-before-AW, AW-before-W, simultaneous channels,
// write byte strobes, boundary addresses and delayed response acceptance.
class axi_protocol_seq extends axi_base_sequence;
  `uvm_object_utils(axi_protocol_seq)
  function new(string name="axi_protocol_seq");
    super.new(name);
  endfunction

  task send_write(bit [31:0] address, bit [31:0] value, bit [3:0] strobe,
                  int aw_delay, int w_delay, int response_delay);
    axi_transaction tr;
    tr=axi_transaction::type_id::create("directed_write");
    start_item(tr);
    tr.trans_type=axi_transaction::WRITE;
    tr.addr=address; tr.data=value; tr.strb=strobe;
    tr.awready_delay=aw_delay; tr.wready_delay=w_delay;
    tr.bvalid_delay=response_delay;
    finish_item(tr);
  endtask

  task send_read(bit [31:0] address, int response_delay);
    axi_transaction tr;
    tr=axi_transaction::type_id::create("directed_read");
    start_item(tr);
    tr.trans_type=axi_transaction::READ;
    tr.addr=address; tr.strb=4'b1111;
    tr.awready_delay=0; tr.wready_delay=0;
    tr.bvalid_delay=response_delay;
    finish_item(tr);
  endtask

  task body();
    // Write address first, write data three cycles later.
    send_write(32'h000,32'h12345678,4'hf,0,3,4);
    send_read(32'h000,3);
    // Write data first, address four cycles later.
    send_write(32'h3fc,32'hdeadbeef,4'hf,4,0,5);
    send_read(32'h3fc,4);
    // Simultaneous AW/W, then a partial update of the same word.
    send_write(32'h100,32'haabbccdd,4'hf,0,0,0);
    send_write(32'h100,32'h11223344,4'b0101,2,0,2);
    send_read(32'h100,5);
    // Back-to-back requests, other strobe lanes, repeated address.
    send_write(32'h004,32'hffffffff,4'hf,1,1,1);
    send_write(32'h004,32'h00112233,4'b1010,0,3,3);
    send_read(32'h004,2);
    // Invalid address requests must return SLVERR with zero read data.
    send_write(32'h400,32'h5555aaaa,4'hf,0,2,3);
    send_read(32'h400,2);
    send_read(32'h002,1);
    send_read(32'h004,0);
  endtask
endclass


// One write with delayed BREADY: reset must cancel the pending response.
class axi_reset_seq extends axi_base_sequence;
  `uvm_object_utils(axi_reset_seq)

  function new(string name = "axi_reset_seq");
    super.new(name);
  endfunction

  task body();
    axi_transaction tr;
    tr = axi_transaction::type_id::create("reset_write");
    start_item(tr);
    tr.trans_type = axi_transaction::WRITE;
    tr.addr = 32'h00000010;
    tr.data = 32'hA5A5A5A5;
    tr.strb = 4'b1111;
    tr.awready_delay = 0;
    tr.wready_delay = 0;
    tr.bvalid_delay = 20; // Keep BREADY low through the second reset.
    finish_item(tr);
  endtask
endclass
