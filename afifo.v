module async_fifo #(
    parameter DATA_WIDTH = 8,   // Width of the data
    parameter DEPTH = 16        // Depth of the FIFO
)(
    input wire                  clk_wr,    // Write clock
    input wire                  clk_rd,    // Read clock
    input wire                  rst,       // Synchronous reset (active high)
    input wire [DATA_WIDTH-1:0] wr_data,   // Data to write
    input wire                  wr_en,     // Write enable
    output wire                 full,      // FIFO full flag
    output wire [DATA_WIDTH-1:0] rd_data,  // Data to read
    input wire                  rd_en,     // Read enable
    output wire                 empty      // FIFO empty flag
);

    localparam ADDR_WIDTH = $clog2(DEPTH); // Address width for FIFO depth

    // Memory array for FIFO
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray, wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray, rd_ptr_gray_sync1, rd_ptr_gray_sync2;

    // Write and read addresses
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];

    
    // Synchronize pointers across clock domains
    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= rd_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= wr_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    
    // Write operation
    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_addr] <= wr_data;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= (wr_ptr_bin + 1) ^ ((wr_ptr_bin + 1) >> 1);
        end
    end

    // Read operation
    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= (rd_ptr_bin + 1) ^ ((rd_ptr_bin + 1) >> 1);
        end
    end

    
    // Generate full and empty flags
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    assign empty = (wr_ptr_gray_sync2 == rd_ptr_gray);

    // Read data output
    assign rd_data = mem[rd_addr];

endmodule
