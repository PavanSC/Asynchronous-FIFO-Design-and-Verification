// Base Test Class
class base_test extends uvm_test;
  seq seqh;
  env envh;
  
  `uvm_component_utils(base_test)
  
  function new(string name = "base_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqh = seq::type_id::create("seqh", this);
    envh = env::type_id::create("envh", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seqh.start(envh.agth.seqrh);
    phase.drop_objection(this);
    phase.phase_done.set_drain_time(this, 100);
  endtask
endclass

// Derived Test Class
class f_test_1 extends uvm_test;
  f_sequence_1 seqh;
  env envh;
  
  `uvm_component_utils(f_test_1)
  
  function new(string name = "f_test_1", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqh = f_sequence_1::type_id::create("seqh", this);
    envh = env::type_id::create("f_env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seqh.start(envh.agth.seqrh);
    phase.drop_objection(this);
    phase.phase_done.set_drain_time(this, 100);
  endtask
endclass