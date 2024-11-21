class agt extends uvm_agent;
  seqr seqrh;
  drv drvh;
  mon monh;
  config cfg;
  `uvm_component_utils(agt)
  
  function new(string name = "agt", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
 

    // Create monitor always
    monh = mon::type_id::create("monh", this);
    
      seqrh = seqr::type_id::create("seqrh", this);
      drvh = drv::type_id::create("drvh", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
      drvh.seq_item_port.connect(seqrh.seq_item_export);
  endfunction
endclass