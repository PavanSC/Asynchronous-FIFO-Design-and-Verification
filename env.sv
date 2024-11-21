class env extends uvm_env;
  agt agth;
  scoreboard sbh;

  
  `uvm_component_utils(env)
  
  function new(string name = "env", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create agent, scoreboard, and coverage components
    agth = agt::type_id::create("agth", this);
    sbh = scoreboard::type_id::create("sbh", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    // Connect monitor's analysis port to scoreboard and coverage
    agth.monh.M2S.connect(sbh.S2M);
  endfunction
endclass