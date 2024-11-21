interface f_interface (
    input logic wr_clk, 
    input logic rd_clk, 
    input logic reset
);
    // Signals for FIFO communication
    logic wr_en;
    logic rd_en;
    logic [31:0] data_in;
    logic fifo_almost_full;
    logic fifo_almost_empty;
    logic fifo_full;
    logic fifo_empty;
    logic [31:0] data_out;

    // Driver Read Clocking Block (with 1ns skew)
    clocking dr_cb @(posedge rd_clk);
        default input #1 output #1;
        output wr_en, rd_en, data_in;
        input fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Driver Write Clocking Block (with 1ns skew)
    clocking dw_cb @(posedge wr_clk);
        default input #1 output #1;
        output wr_en, rd_en, data_in;
        input fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Monitor Read Clocking Block (with 2ns skew)
    clocking mr_cb @(posedge rd_clk);
        default input #2 output #2;
        input wr_en, rd_en, data_in, 
              fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Monitor Write Clocking Block (with 2ns skew)
    clocking mw_cb @(posedge wr_clk);
        default input #2 output #2;
        input wr_en, rd_en, data_in, 
              fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Modports for different usage contexts
    modport driver_read (
        input rd_clk, reset, 
        clocking dr_cb
    );

    modport driver_write (
        input wr_clk, reset, 
        clocking dw_cb
    );

    modport monitor_read (
        input rd_clk, reset, 
        clocking mr_cb
    );

    modport monitor_write (
        input wr_clk, reset, 
        clocking mw_cb
    );

endinterface : f_interface
