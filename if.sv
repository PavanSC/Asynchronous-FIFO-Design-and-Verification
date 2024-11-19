interface afifo_if(input bit clk_wr,clk_rd,rst);


logic wr_en;
logic rd_en;
logic full;
logic empty;
logic [7:0] wr_data;
logic [7:0] rd_data;


clocking wr_drv_cb @(posedge clk_wr);

 output wr_data;
 output wr_en;
 input rst;
 input full;
 input empty;
endclocking


clocking rd_drv_cb @(posedge clk_rd);

 input rd_data;
 input rst;
 input empty;
 output rd_en;
endclocking



clocking wr_mon_cb @(posedge clk_wr);

 input wr_data;
 input wr_en;
 input full;
 input empty;
endclocking


clocking rd_mon_cb @(posedge clk_rd);
 
 input rd_data;
 input rd_en;
 input full;
 input empty;
endclocking

modport WDRV_MP (clocking wr_drv_cb, input clk_wr, clk_rd, rst);
modport WMON_MP (clocking wr_mon_cb, input clk_wr, clk_rd, rst);
modport RDRV_MP (clocking rd_drv_cb, input clk_wr, clk_rd, rst);
modport RMON_MP (clocking rd_mon_cb, input clk_wr, clk_rd, rst);


endinterface