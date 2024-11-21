class scoreboard extends uvm_scoreboard;
  uvm_analysis_imp#(trans, scoreboard) S2M;
  
  // Coverage group
  covergroup fifo_coverage;
    // Write operation coverage
    write_op: coverpoint write_op_type {
      bins write_single = {SINGLE_WRITE};
      bins write_multiple = {MULTIPLE_WRITE};
      bins write_full_fifo = {FULL_FIFO_WRITE};
    }
    
    // Read operation coverage
    read_op: coverpoint read_op_type {
      bins read_single = {SINGLE_READ};
      bins read_multiple = {MULTIPLE_READ};
      bins read_empty_fifo = {EMPTY_FIFO_READ};
    }
    
    // Data value coverage
    data_value: coverpoint current_data {
      bins low_range = {[0:32'h3FFF]};
      bins mid_range = {[32'h4000:32'h7FFF]};
      bins high_range = {[32'h8000:32'hFFFF]};
    }
    
    // FIFO status cross coverage
    status_cross: cross write_op, read_op;
  endgroup
  
  // Enum for tracking operation types
  typedef enum {IDLE, SINGLE_WRITE, MULTIPLE_WRITE, FULL_FIFO_WRITE} write_op_e;
  typedef enum {IDLE, SINGLE_READ, MULTIPLE_READ, EMPTY_FIFO_READ} read_op_e;
  
  // Coverage tracking variables
  write_op_e write_op_type;
  read_op_e read_op_type;
  bit [31:0] current_data;
  int write_count, read_count;
  
  `uvm_component_utils(scoreboard)
  
  function new(string name = "scoreboard", uvm_component parent);
    super.new(name, parent);
    S2M = new("S2M", this);
    fifo_coverage = new();
    write_count = 0;
    read_count = 0;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  int queue[$];
  
  function void write(input trans item_got);
    bit [31:0] examdata;
    
    // Write operation handling and coverage
    if(item_got.wr_en == 'b1) begin
      queue.push_back(item_got.data_in);
      write_count++;
      current_data = item_got.data_in;
      
      // Update write operation type
      if(write_count == 1)
        write_op_type = SINGLE_WRITE;
      else if(item_got.fifo_full)
        write_op_type = FULL_FIFO_WRITE;
      else
        write_op_type = MULTIPLE_WRITE;
      
      `uvm_info("Write Data", $sformatf("Q size = %0d, data = %0h", queue.size(), item_got.data_in), UVM_LOW);
    end
    
    // Read operation handling and coverage
    if (item_got.rd_en == 'b1) begin
      read_count++;
      
      if(queue.size() == 0) begin
        read_op_type = EMPTY_FIFO_READ;
        `uvm_info("Read Data", "Read enabled when FIFO is empty", UVM_LOW);
      end
      else begin
        examdata = queue.pop_front();
        
        // Update read operation type
        if(read_count == 1)
          read_op_type = SINGLE_READ;
        else
          read_op_type = MULTIPLE_READ;
        
        // Sample coverage
        fifo_coverage.sample();
        
        `uvm_info("Read Data", $sformatf("Expected: %0h, Actual: %0h", examdata, item_got.data_out), UVM_LOW);
        
        // Comparison and reporting
        if(examdata == item_got.data_out)
          $display("-------- Pass! --------");
        else begin
          $display("--------	Fail!	--------");
          $display("--------	Check data	--------");
        end
      end
    end
  endfunction
  
  // Report coverage at end of simulation
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("Coverage: %0.2f%%", fifo_coverage.get_coverage());
  endfunction
endclass