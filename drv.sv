class drv extends uvm_driver#(trans);
  virtual afifo_if vif;
  trans req;
  bit [1:0] en_rd_wr;
  `uvm_component_utils(drv)
  
  function new(string name = "drv", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual afifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("Driver: ", "No vif is found!")
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      en_rd_wr[0] = req.wr_en;
      en_rd_wr[1] = req.rd_en;
      case (en_rd_wr) 
        2'b00 : main_idle();
        2'b01 : main_write(req.data_in);
        2'b10 : main_read();
        2'b11 : main_rd_wr(req.data_in);
      endcase
      #10;
      seq_item_port.item_done();
     end
  endtask
  
  virtual task main_write(input [31:0] din);
    @(posedge vif.WDRV_MP.wr_clk)
    `uvm_info(get_name(),"DEBUG :: ADI :: posedge detected",UVM_LOW);
    vif.WDRV_MP.wdrv_cb.wr_en <= 'b1;
    vif.WDRV_MP.wdrv_cb.data_in <= din;
    #20;
    `uvm_info(get_name(),"DEBUG :: ADI :: next posedge detected",UVM_LOW);
    vif.WDRV_MP.wdrv_cb.wr_en <= 'b0;
  endtask
  
  virtual task main_read();
    `uvm_info(get_name(),"DEBUG :: ADI :: main_read called",UVM_LOW);
    @(posedge vif.RDRV_MP.rd_clk)
    vif.RDRV_MP.rdrv_cb.rd_en <= 'b1;
    #40;
    vif.RDRV_MP.rdrv_cb.rd_en <= 'b0;
  endtask
    
  virtual task main_rd_wr(input [31:0] din);
    `uvm_info(get_name(),"DEBUG :: ADI :: main_rd_wr called",UVM_LOW);
    fork 
      begin 
        main_write(din);
      end
      begin
        main_read();
      end
    join 
  endtask
  
  virtual task main_idle();
    `uvm_info(get_name(),"DEBUG :: ADI :: main_idle called",UVM_LOW);
    @(posedge vif.RDRV_MP.rd_clk)
    vif.RDRV_MP.rdrv_cb.rd_en <= 'b0;
    @(posedge vif.WRDV_MP.wr_clk)
    vif.WRDV_MP.wdrv_cb.wr_en <= 'b0;
  endtask
endclass