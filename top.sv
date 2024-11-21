module top;
  import uvm_pkg::*;
  import afifo_pkf::*;
  `include "uvm_macros.svh"
  
  // Parameters
  parameter DATA_WIDTH = 32;
  parameter FIFO_DEPTH = 16; 
  
  // Signals
  bit wr_clk;
  bit rd_clk;
  bit reset;
  
  // Clock generation
  always #10 wr_clk = ~wr_clk;
  always #20 rd_clk = ~rd_clk;
  
  // Interface instantiation
  afifo_if tif(wr_clk, rd_clk, reset);
  
  // DUT instantiation
  async_fifo #(
    .DATA_WIDTH(DATA_WIDTH), 
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .wr_clk(tif.wr_clk),
    .rd_clk(tif.rd_clk),
    .reset(tif.reset),
    .wr_data(tif.wr_data),
    .wr_en(tif.wr_en),
    .rd_en(tif.rd_en),
    .fifo_full(tif.fifo_full),
    .fifo_empty(tif.fifo_empty),
    .fifo_almost_full(tif.fifo_almost_full),
    .fifo_almost_empty(tif.fifo_almost_empty),
    .rd_data(tif.rd_data)
  );
  
  // Assertions
  // Prevent simultaneous read and write when FIFO is full/empty
  assert_no_simultaneous_rw: assert property (
    @(posedge wr_clk) 
    disable iff (reset)
    !(tif.wr_en && tif.rd_en)
  ) else $error("Simultaneous read and write not allowed");
  
  // Check FIFO full condition
  assert_fifo_full: assert property (
    @(posedge wr_clk) 
    disable iff (reset)
    (tif.wr_en && tif.fifo_full) |-> ##1 tif.fifo_full
  ) else $error("FIFO full status not maintained");
  
  // Check FIFO empty condition
  assert_fifo_empty: assert property (
    @(posedge rd_clk) 
    disable iff (reset)
    (tif.rd_en && tif.fifo_empty) |-> ##1 tif.fifo_empty
  ) else $error("FIFO empty status not maintained");
  
  // Prevent write to full FIFO
  assert_no_write_when_full: assert property (
    @(posedge wr_clk) 
    disable iff (reset)
    tif.fifo_full |-> !tif.wr_en
  ) else $error("Write attempted to full FIFO");
  
  // Prevent read from empty FIFO
  assert_no_read_when_empty: assert property (
    @(posedge rd_clk) 
    disable iff (reset)
    tif.fifo_empty |-> !tif.rd_en
  ) else $error("Read attempted from empty FIFO");
  
  // Initialization and Test Setup
  initial begin
    // Reset initialization
    wr_clk = 0;
    rd_clk = 0;
    reset = 1;
    #5 reset = 0;
    
    // UVM Configuration
    uvm_config_db#(virtual afifo_if)::set(null, "", "vif", tif);
    
    // VCD Dumping
    $dumpfile("fifo_simulation.vcd"); 
    $dumpvars(0, top);
    
    // Run Test
    run_test("f_test");
    // Alternative test can be run by uncommenting
    // run_test("f_test_1");
  end
endmodule