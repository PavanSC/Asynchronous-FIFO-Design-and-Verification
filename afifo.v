`include "dual_port_ram.sv"
`include "shift_register.sv"
module async_fifo#(
  parameter DATA_WIDTH = 32,   
  parameter FIFO_DEPTH = 16)   
(
  input  logic wr_clk, rd_clk, 
  input  logic reset,          
  input  logic wr_en, 
  input  logic rd_en, 
  input  logic [DATA_WIDTH-1:0] data_in,  
  output logic [DATA_WIDTH-1:0] data_out, 
  output logic fifo_full, 
  output logic fifo_empty, 
  output logic fifo_almost_full, 
  output logic fifo_almost_empty 
);

 localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
  
from rd_ptr_gray2 gray counting read address pointer
 logic [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray2, wr_ptr_binary2;
 logic [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray2, rd_ptr_binary2;
 logic t_fifo_empty, t_fifo_full;

  always_ff@(posedge wr_clk,posedge reset) begin
   
   if (reset == 1)
    wr_ptr <= 0;
  else begin
    if ((wr_en == 1) && !fifo_almost_full)
      wr_ptr <= wr_ptr + 1;
  end
 end

 assign wr_ptr_gray =  binary_to_gray(wr_ptr);

 always_ff@(posedge rd_clk,posedge reset) begin
     
	 if (reset == 1)
    rd_ptr <= 0;
  else begin
    if ((rd_en == 1) && !fifo_almost_empty)
      rd_ptr <= rd_ptr + 1;
  end
 end

 assign rd_ptr_gray = binary_to_gray(rd_ptr);
 assign t_fifo_empty =  (rd_ptr == wr_ptr_binary2) ? 1 : 0;
 assign fifo_almost_empty =  t_fifo_empty;
 assign t_fifo_full  =   ((wr_ptr[ADDR_WIDTH] != rd_ptr_binary2[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_binary2[ADDR_WIDTH-1:0])) ? 1 : 0;
 assign fifo_almost_full =  t_fifo_full;
	

 dual_port_ram #(
   .DATA_WIDTH(DATA_WIDTH),
   .ADDR_WIDTH(ADDR_WIDTH)) 
 fifo_memory_inst(
	 .wr_clk(wr_clk),
    .reset(reset),
    .wr_en(wr_en && !fifo_full),
    .write_data(data_in),
   .write_addr(wr_ptr[ADDR_WIDTH-1:0]),
    .rd_en(rd_en && !fifo_empty),
    .read_addr(rd_ptr[ADDR_WIDTH-1:0]),
    .read_data(data_out)
 );
 

 shift_register #(
  .WIDTH(ADDR_WIDTH), 
  .NUM_OF_STAGES(2)) 
 wr_ptr_synchronizer_inst(
  .clk(rd_clk),
  .reset(reset),
  .d(wr_ptr_gray),
  .q(wr_ptr_gray2)
 );

 assign wr_ptr_binary2 = gray_to_binary(wr_ptr_gray2); 

 shift_register #(
    .WIDTH(ADDR_WIDTH),
  .NUM_OF_STAGES(2))
  rd_ptr_synchronizer_inst(
    .clk(wr_clk),
    .reset(reset),
    .d(rd_ptr_gray),
    .q(rd_ptr_gray2)
 );

 assign rd_ptr_binary2 =  gray_to_binary(rd_ptr_gray2);

 shift_register #(
  .WIDTH(1), 
  .NUM_OF_STAGES(1),   
  .RESET_VALUE(1))  
 fifo_empty_inst(
  .clk(rd_clk),
  .reset(reset),
  .d(t_fifo_empty),
  .q(fifo_empty)
 );

 shift_register #( 
	.WIDTH(1),
    .NUM_OF_STAGES(1),
    .RESET_VALUE(0))
    fifo_full_inst(
      .clk(wr_clk),
      .reset(reset),
      .d(t_fifo_full),
      .q(fifo_full)
 );
 
 // function to convert binary to gray function
 function automatic [ADDR_WIDTH:0] binary_to_gray(logic [ADDR_WIDTH:0] value);
   begin 
     binary_to_gray[ADDR_WIDTH] = value[ADDR_WIDTH];
     for(int i=ADDR_WIDTH; i>0; i = i - 1)
       binary_to_gray[i-1] = value[i] ^ value[i - 1];
    end
 endfunction

 // function to convert gray to binary  
 function logic[ADDR_WIDTH:0] gray_to_binary(logic[ADDR_WIDTH:0] value);
  begin 
     logic[ADDR_WIDTH:0] l_binary_value;
     l_binary_value[ADDR_WIDTH] = value[ADDR_WIDTH];
     for(int i=ADDR_WIDTH; i>0; i = i - 1) begin
      l_binary_value[i-1] = value[i-1] ^ l_binary_value[i];
     end
     gray_to_binary = l_binary_value;
  end
 endfunction
 
endmodule:async_fifo
