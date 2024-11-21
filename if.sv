interface afifo_if (
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
    clocking rdrv_cb @(posedge rd_clk);
        default input #1 output #1;
        output wr_en, rd_en, data_in;
        input fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Driver Write Clocking Block (with 1ns skew)
    clocking wdrv_cb @(posedge wr_clk);
        default input #1 output #1;
        output wr_en, rd_en, data_in;
        input fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Monitor Read Clocking Block (with 2ns skew)
    clocking rmon_cb @(posedge rd_clk);
        default input #2 output #2;
        input wr_en, rd_en, data_in, 
              fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Monitor Write Clocking Block (with 2ns skew)
    clocking wmon_cb @(posedge wr_clk);
        default input #2 output #2;
        input wr_en, rd_en, data_in, 
              fifo_full, fifo_empty, 
              fifo_almost_full, fifo_almost_empty, 
              data_out;
    endclocking

    // Modports for different usage contexts
    modport RDRV_MP (
        input rd_clk, reset, 
        clocking dr_cb
    );

    modport WDRV_MP (
        input wr_clk, reset, 
        clocking dw_cb
    );

    modport RMON_MP (
        input rd_clk, reset, 
        clocking mr_cb
    );

    modport WMON_MP (
        input wr_clk, reset, 
        clocking mw_cb
    );

endinterface : afifo_if
