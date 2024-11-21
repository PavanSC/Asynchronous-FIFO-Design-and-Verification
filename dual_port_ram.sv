`timescale 1ns/1ps

module dual_port_ram #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 3
)(
    input logic wr_clk,
    input logic reset,
    input logic wr_en,
    input logic [DATA_WIDTH-1:0] write_data, 
    input logic [ADDR_WIDTH-1:0] write_addr,
 
    input logic rd_en, 
    input logic [ADDR_WIDTH-1:0] read_addr,
    output logic [DATA_WIDTH-1:0] read_data
);
    // Memory Array and Read Register
    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];
    logic [DATA_WIDTH-1:0] read_data_reg;

    // Synchronous Write with Reset
    always_ff @(posedge wr_clk) begin 
        if (reset) begin
            // Memory initialization
            for (int unsigned i = 0; i < 2**ADDR_WIDTH; i++) begin
                mem[i] <= '0;
            end
        end 
        else begin
            // Write operation
            if (wr_en) begin
                mem[write_addr] <= write_data;
            end
        end
    end  

    // Read Logic with Previous Address Behavior
    always_ff @(posedge wr_clk) begin
        if (rd_en) begin
            read_data_reg <= mem[read_addr];
        end
        else begin
            // When rd_en is low, maintain previous address's data
            read_data_reg <= mem[read_addr-1];
        end
    end

    // Output Assignment
    assign read_data = read_data_reg;

endmodule : dual_port_ram