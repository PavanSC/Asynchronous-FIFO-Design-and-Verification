class seq extends uvm_sequence#(trans);
  `uvm_object_utils(seq)
  
  // Enum for test phases
  typedef enum {EMPTY_CHECK, WRITE_PHASE, FULL_CHECK, READ_PHASE, RANDOM_PHASE, FINAL_PHASE} test_phase_e;
  
  // Configuration variables
  local int max_write_count = 8;
  local int max_read_count = 8;
  local int max_random_count = 20;
  local int max_concurrent_count = 10;
  
  // Status tracking
  protected bit fifo_full, fifo_empty;
  
  function new(string name = "seq");
    super.new(name);
  endfunction
  
  // Helper task to read FIFO status
  protected task read_fifo_status();
    uvm_hdl_read("tb.dut.fifo_empty", fifo_empty);
    uvm_hdl_read("tb.dut.fifo_full", fifo_full);
  endtask
  
  // Generate transaction with constraints
  protected task generate_constrained_req(input bit force_wr = 0, input bit force_rd = 0);
    req = f_sequence_item::type_id::create("req");
    start_item(req);
    
    if (force_wr || force_rd) begin
      assert(req.randomize() with {
        wr_en == force_wr;
        rd_en == force_rd;
      });
    end else begin
      read_fifo_status();
      if (fifo_empty || fifo_full) begin
        assert(req.randomize() with {
          rd_en == fifo_full;
          wr_en == fifo_empty;
        });
      end else begin
        assert(req.randomize());
      end
    end
    
    `uvm_info(get_type_name(), 
      $sformatf("Generated req: wr_en = %0d, rd_en = %0d", req.wr_en, req.rd_en), 
      UVM_LOW
    );
    
    finish_item(req);
  endtask
  
  // Monitor FIFO status with timeout
  protected task monitor_fifo_status(
    input string status_signal, 
    input int timeout = 100, 
    input bit expected_value = 1
  );
    fork
      begin
        forever begin
          bit current_status;
          uvm_hdl_read(status_signal, current_status);
          #2;
          if (current_status == expected_value) begin 
            `uvm_info(get_name(), 
              $sformatf("%s gets asserted", status_signal), 
              UVM_LOW
            );
            break;
          end 
        end 
      end 
      begin
        #timeout;
        `uvm_error(get_name(), 
          $sformatf("%s not equal to %0d within timeout", status_signal, expected_value)
        );
      end 
    join_any
    disable fork;
  endtask
  
  virtual task body();
    // Initial Empty Check
    `uvm_info(get_type_name(), "******** Checking FIFO Empty State ********", UVM_LOW);
    #20;
    read_fifo_status();
    if(!fifo_empty) 
      `uvm_error(get_name(), "FIFO not empty at start");
    
    // Write Phase
    `uvm_info(get_type_name(), "******** Generate Write Requests ********", UVM_LOW);
    repeat(max_write_count) begin
      generate_constrained_req(.force_wr(1));
    end
    
    // Full Check
    monitor_fifo_status("tb.dut.fifo_full");
    
    // Read Phase
    `uvm_info(get_type_name(), "******** Generate Read Requests ********", UVM_LOW);
    repeat(max_read_count) begin
      generate_constrained_req(.force_rd(1));
    end
    
    // Empty Check
    monitor_fifo_status("tb.dut.fifo_empty");
    
    // Random Phase
    `uvm_info(get_type_name(), "******** Generate Random Requests ********", UVM_LOW);
    repeat(max_random_count) begin
      generate_constrained_req();
    end
    
    // Additional Write
    `uvm_info(get_type_name(), "******** Final Write Requests ********", UVM_LOW);
    repeat(2) begin
      generate_constrained_req(.force_wr(1));
    end
    
    // Concurrent Read/Write
    `uvm_info(get_type_name(), "******** Concurrent Read/Write Requests ********", UVM_LOW);
    repeat(max_concurrent_count) begin
      req = f_sequence_item::type_id::create("req");
      start_item(req);
      req.wr_rd2.constraint_mode(0);
      assert(req.randomize() with {rd_en == 1; wr_en == 1;});
      finish_item(req);
    end
  endtask
endclass

class f_sequence_1 extends uvm_sequence#(trans);
  `uvm_object_utils(f_sequence_1)
  
  function new(string name = "f_sequence_1");
    super.new(name);
  endfunction
  
  virtual task body();
    bit fifo_empty;
    
    `uvm_info(get_type_name(), "******** Checking Initial FIFO State ********", UVM_LOW);
    #10;
    uvm_hdl_read("tb.dut.fifo_empty", fifo_empty);
    
    if(!fifo_empty) 
      `uvm_error(get_name(), "FIFO not empty at start");
    
    `uvm_info(get_type_name(), "******** Generate Random Requests ********", UVM_LOW);
    repeat(8) begin
      req = f_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      `uvm_info(get_type_name(), 
        $sformatf("Generated req: wr_en = %0d, rd_en = %0d", req.wr_en, req.rd_en), 
        UVM_LOW
      );
      finish_item(req);
    end
  endtask
endclass