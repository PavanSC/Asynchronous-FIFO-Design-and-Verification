class mon extends uvm_monitor;
  virtual afifo_if vif;
  trans data;
  uvm_analysis_port#(trans) M2S;
  
  `uvm_component_utils(mon)
  
  function new(string name = "mon", uvm_component parent);
    super.new(name, parent);
    M2S = new("M2S", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual afifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("Monitor", "No virtual interface found!")
  endfunction
      
  virtual task run_phase(uvm_phase phase);
    fork
      monitor_write();
      monitor_read();
    join
  endtask

  // Separate task for write monitoring
  task monitor_write();
    forever begin 
      @(posedge vif.WMON_MP.wr_clk);
      if(vif.WMON_MP.wmon_cb.wr_en) begin
        data = trans::type_id::create("data");
        data.data_in = vif.WMON_MP.wmon_cb.data_in;
        data.wr_en = 1'b1;
        data.rd_en = 1'b0;
        data.fifo_full = vif.WMON_MP.wmon_cb.fifo_full;
        M2S.write(data);
      end
    end 
  endtask

  // Separate task for read monitoring  
  task monitor_read();
    forever begin
      @(posedge vif.RMON_MP.rd_clk);
      if(vif.RMON_MP.rmon_cb.rd_en) begin
        data = trans::type_id::create("data");
        data.data_out = vif.RMON_MP.rmon_cb.data_out;
        data.rd_en = 1'b1;
        data.wr_en = 1'b0;
        data.fifo_empty = vif.RMON_MP.rmon_cb.fifo_empty;
        M2S.write(data);
      end
    end 
  endtask
endclass