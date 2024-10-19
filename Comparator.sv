// ===============================================================================
// Module Name:    Comparator
// Project Name:   Formal Property Verification
// Description: 
//     This module implements a comparator that sorts multiple input data
//     and outputs either the smallest or largest value based on the selected 
//     mode. It utilizes an insertion sort algorithm to sort the data 
//     inputs and provides a flag to indicate when sorting is completed.
// 
// Port Description:
//     Name           Dir   Width                         Description
//     ---------------------------------------------------------------------------
//     CLK            In    1                             System clock input
//     RST_N          In    1                             Asynchronous reset (active low)
//     MODE           In    1                             Mode select; 0 for smallest, 1 for largest
//     DIN            In    [DATA_WIDTH*NUM_INPUTS-1:0]   Combined input data from multiple sources
//     DOUT           Out   [DATA_WIDTH-1:0]              Sorted output data; either smallest or largest
//     SORT_DONE      Out   1                             Indicates when sorting has been completed
//
// Parameters:
//     DATA_WIDTH     - Configurable width of each data input (default is 16 bits)
//     NUM_INPUTS     - Configurable number of input data (default is 8 inputs)
//
// How to Use:
//     1. Ensure the system clock (CLK) and asynchronous reset (RST_N) are connected properly.
//        - The reset (RST_N) should be active low to initialize the sorting process and clear outputs.
//     2. Configure the module by setting DATA_WIDTH and NUM_INPUTS as required.
//     3. To start sorting:
//        - Provide input data on DIN and assert RST_N low for reset.
//        - Once RST_N is released, the module will read the data inputs, 
//          and the sorting process will begin at 1 clock cycle later.
//     4. To get the output:
//        - After sorting is complete (SORT_DONE goes high), read the sorted value from DOUT.
//        - DOUT will output the smallest or largest value based on the MODE signal.
//        - Make sure only sample DOUT when SORT_DONE is high to get the correct result.
//     5. Example:
//        - Set DIN = {16'd45, 16'd3, 16'd29, 16'd88}, 
//          MODE = 0 will find the smallest value (DOUT = 16'd3).
//          MODE = 1 will find the largest value (DOUT = 16'd88).
// 
// Dependencies: 
//     None
// 
// Author:         Ting-An Cheng
// Date:           2024-10-19
// Last Modified:  2024-10-19
// Version:        1.0
// 
// Revision History:
//     2024-10-19 - 1.0 - Initial release
// ===============================================================================



module Comparator #(
    parameter DATA_WIDTH = 16,                      // Data width
    parameter NUM_INPUTS = 8                        // Number of inputs
)(
    input  wire CLK,                                // Clock
    input  wire RST_N,                              // Asynchronous reset (active low)
    input  wire MODE,                               // 0: Output smallest, 1: Output largest
    input  wire [DATA_WIDTH*NUM_INPUTS-1:0] DIN,    // Combined input of multiple data
    output reg  [DATA_WIDTH-1:0] DOUT,              // Output result
    output reg  SORT_DONE                           // Sorting completion flag
);

    reg [DATA_WIDTH-1:0] data [0:NUM_INPUTS-1];     // Data array
    reg [DATA_WIDTH-1:0] current_value;             // Temporary variable for the current value being sorted
    reg is_sorting_started;                         // Flag to indicate if sorting has started
    int comparison_index;                           // Loop variable for comparison

    // Insertion Sort Algorithm
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            SORT_DONE <= 1'b0;
            is_sorting_started <= 1'b0;
        end else if (!is_sorting_started) begin
            for (int ii = 0; ii < NUM_INPUTS; ii++) begin
                data[ii] <= DIN[(ii * DATA_WIDTH) +: DATA_WIDTH];
            end
            is_sorting_started <= 1'b1;
        end else if (is_sorting_started && !SORT_DONE) begin
            for (int ii = 1; ii < NUM_INPUTS; ii++) begin
                current_value = data[ii];
                comparison_index = ii - 1;
                while (comparison_index >= 0 && data[comparison_index] > current_value) begin
                    data[comparison_index + 1] = data[comparison_index];
                    comparison_index = comparison_index - 1;
                end
                data[comparison_index + 1] = current_value;
            end

            SORT_DONE <= 1;
        end
    end

    always @(*) begin
        if (!RST_N) begin
            DOUT <= 0;
        end else begin
            DOUT <= SORT_DONE ? (MODE == 0 ? data[0] : data[NUM_INPUTS - 1]) : 0;
        end
    end

endmodule
