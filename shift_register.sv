`timescale 1ns/1ps

module shift_register #(
    parameter int WIDTH = 3, 
    parameter int NUM_OF_STAGES = 2,
    parameter logic [WIDTH-1:0] RESET_VALUE = '0
)(
    input logic clk, 
    input logic reset, 
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    // Shift register storage
    logic [WIDTH-1:0] shift_stages [NUM_OF_STAGES];

    // Synchronous shift register logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all stages to reset value
            for (int unsigned i = 0; i < NUM_OF_STAGES; i++) begin
                shift_stages[i] <= RESET_VALUE;
            end
        end
        else begin
            // Shift data through stages
            shift_stages[0] <= d;
            for (int unsigned i = 0; i < NUM_OF_STAGES - 1; i++) begin
                shift_stages[i+1] <= shift_stages[i];
            end
        end
    end

    // Output assignment
    assign q = shift_stages[NUM_OF_STAGES-1];

endmodule : shift_register