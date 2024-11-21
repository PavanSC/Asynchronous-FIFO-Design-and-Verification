`include "dual_port_ram.sv"
`include "shift_register.sv"

module async_fifo #(
    parameter int DATA_WIDTH = 32,   // Width of each data element in FIFO Memory
    parameter int FIFO_DEPTH = 16    // Number of locations in FIFO Memory
)(
    // Clock and Reset Inputs
    input logic wr_clk, rd_clk,      // Write and Read Clocks
    input logic reset,                // Common reset

    // Control Inputs
    input logic wr_en,                // Write enable
    input logic rd_en,                // Read enable
    
    // Data Inputs and Outputs
    input  logic [DATA_WIDTH-1:0] data_in,   // Input data to be written
    output logic [DATA_WIDTH-1:0] data_out,  // Data read out from FIFO

    // Status Outputs
    output logic fifo_full,           // FIFO is full
    output logic fifo_empty,          // FIFO is empty
    output logic fifo_almost_full,    // One cycle early full indication
    output logic fifo_almost_empty    // One cycle early empty indication
);

    // Derived Parameters
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Internal Pointer Signals
    logic [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray, wr_ptr_gray2, wr_ptr_binary2;
    logic [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray, rd_ptr_gray2, rd_ptr_binary2;
    
    // Internal Status Flags
    logic t_fifo_empty, t_fifo_full;

    // Write Pointer Management
    always_ff @(posedge wr_clk or posedge reset) begin
        if (reset)
            wr_ptr <= '0;
        else if (wr_en && !fifo_almost_full)
            wr_ptr <= wr_ptr + 1;
    end

    // Read Pointer Management
    always_ff @(posedge rd_clk or posedge reset) begin
        if (reset)
            rd_ptr <= '0;
        else if (rd_en && !fifo_almost_empty)
            rd_ptr <= rd_ptr + 1;
    end

    // Pointer Conversion to Gray Code
    assign wr_ptr_gray = binary_to_gray(wr_ptr);
    assign rd_ptr_gray = binary_to_gray(rd_ptr);

    // Write Pointer Synchronization to Read Clock Domain
    shift_register #(
        .WIDTH(ADDR_WIDTH),
        .NUM_OF_STAGES(2)
    ) wr_ptr_synchronizer_inst (
        .clk(rd_clk),
        .reset(reset),
        .d(wr_ptr_gray),
        .q(wr_ptr_gray2)
    );

    // Read Pointer Synchronization to Write Clock Domain
    shift_register #(
        .WIDTH(ADDR_WIDTH),
        .NUM_OF_STAGES(2)
    ) rd_ptr_synchronizer_inst (
        .clk(wr_clk),
        .reset(reset),
        .d(rd_ptr_gray),
        .q(rd_ptr_gray2)
    );

    // Convert Synchronized Gray Pointers Back to Binary
    assign wr_ptr_binary2 = gray_to_binary(wr_ptr_gray2);
    assign rd_ptr_binary2 = gray_to_binary(rd_ptr_gray2);

    // FIFO Empty Flag Generation
    assign t_fifo_empty = (rd_ptr == wr_ptr_binary2);
    assign fifo_almost_empty = t_fifo_empty;

    // Delayed Empty Flag
    shift_register #(
        .WIDTH(1),
        .NUM_OF_STAGES(1),
        .RESET_VALUE(1)
    ) fifo_empty_inst (
        .clk(rd_clk),
        .reset(reset),
        .d(t_fifo_empty),
        .q(fifo_empty)
    );

    // FIFO Full Flag Generation
    assign t_fifo_full = ((wr_ptr[ADDR_WIDTH] != rd_ptr_binary2[ADDR_WIDTH]) && 
                          (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_binary2[ADDR_WIDTH-1:0])) ? 1 : 0;
    assign fifo_almost_full = t_fifo_full;

    // Delayed Full Flag
    shift_register #(
        .WIDTH(1),
        .NUM_OF_STAGES(1),
        .RESET_VALUE(0)
    ) fifo_full_inst (
        .clk(wr_clk),
        .reset(reset),
        .d(t_fifo_full),
        .q(fifo_full)
    );

    // Dual-Port RAM for FIFO Memory
    dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory_inst (
        .wr_clk(wr_clk),
        .reset(reset),
        .wr_en(wr_en && !fifo_full),
        .write_data(data_in),
        .write_addr(wr_ptr[ADDR_WIDTH-1:0]),
        .rd_en(rd_en && !fifo_empty),
        .read_addr(rd_ptr[ADDR_WIDTH-1:0]),
        .read_data(data_out)
    );

    // Binary to Gray Code Conversion Function
    function automatic logic [ADDR_WIDTH:0] binary_to_gray(
        input logic [ADDR_WIDTH:0] value
    );
        binary_to_gray[ADDR_WIDTH] = value[ADDR_WIDTH];
        for (int i = ADDR_WIDTH; i > 0; i--) begin
            binary_to_gray[i-1] = value[i] ^ value[i-1];
        end
        return binary_to_gray;
    endfunction

    // Gray to Binary Code Conversion Function
    function automatic logic [ADDR_WIDTH:0] gray_to_binary(
        input logic [ADDR_WIDTH:0] value
    );
        logic [ADDR_WIDTH:0] l_binary_value;
        l_binary_value[ADDR_WIDTH] = value[ADDR_WIDTH];
        for (int i = ADDR_WIDTH; i > 0; i--) begin
            l_binary_value[i-1] = value[i-1] ^ l_binary_value[i];
        end
        return l_binary_value;
    endfunction

endmodule : async_fifo
