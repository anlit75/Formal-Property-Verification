// ===============================================================================
// Module Name:    FIFO
// Project Name:   Formal Property Verification
// Description: 
//     This module implements a simple First-In-First-Out (FIFO)
//     buffer. It provides basic FIFO functionality with 
//     configurable data width and depth, using write and read 
//     enable signals to control data flow. The module includes
//     FULL and EMPTY indicators to signal the status of the FIFO.
// 
// Port Description:
//     Name           Dir   Width              Description
//     -------------------------------------------------------------
//     CLK            In    1                  System clock input
//     RST_N          In    1                  Asynchronous reset
//     WR_EN          In    1                  Write enable; when high, data is written to FIFO
//     RD_EN          In    1                  Read enable; when high, data is read from FIFO
//     DIN            In    [DATA_WIDTH-1:0]   Data input to be stored in FIFO
//     DOUT           Out   [DATA_WIDTH-1:0]   Data output from the FIFO
//     FULL           Out   1                  Indicates when FIFO is full and cannot accept new data
//     EMPTY          Out   1                  Indicates when FIFO is empty and there is no data to read
//
// Parameters:
//     DATA_WIDTH     - Configurable width of the data bus (default is 8 bits)
//     FIFO_DEPTH     - Configurable depth of the FIFO buffer (default is 16)
//
// How to Use:
//     1. Ensure the system clock (CLK) and asynchronous reset (RST_N) are connected properly.
//        - The reset (RST_N) should be active low to initialize the FIFO pointers and status flags.
//     2. Configure the module by setting DATA_WIDTH and FIFO_DEPTH as required.
//     3. To write data to the FIFO:
//        - Ensure WR_EN is set to high, RD_EN is set to low, and provide data on DIN.
//        - The FIFO will write data only if it is not FULL.
//        - Check the FULL signal to avoid overwriting data.
//     4. To read data from the FIFO:
//        - Ensure RD_EN is set to high, WD_EN is set to low, and read data from DOUT.
//        - The FIFO will provide data only if it is not EMPTY.
//        - Check the EMPTY signal to avoid reading invalid data.
//     5. Example:
//        - Set WR_EN = 1, RD_EN = 0, DIN = 8'b10101010 to write data.
//        - Set RD_EN = 1, WR_EN = 0 to read the next available data from DOUT.
//        - If set WR_EN = 1, RD_EN = 1, the FIFO will do nothing.
//
// Dependencies: 
//     None
// 
// Author:         Ting-An Cheng
// Date:           2024-10-18
// Last Modified:  2024-10-19
// Version:        1.1
// 
// Revision History:
//     2024-10-18 - 1.0 - Initial release
//     2024-10-19 - 1.1 - Modified output port to be registered
// ===============================================================================


module FIFO #(
    parameter DATA_WIDTH = 8,           // Data width
    parameter FIFO_DEPTH = 16           // FIFO depth
)(
    input  wire CLK,                    // Clock
    input  wire RST_N,                  // Asynchronous reset
    input  wire WR_EN,                  // Write enable signal
    input  wire RD_EN,                  // Read enable signal
    input  wire [DATA_WIDTH-1:0] DIN,   // Write data
    output reg  [DATA_WIDTH-1:0] DOUT,  // Read data
    output reg  FULL,                   // FIFO FULL indicator
    output reg  EMPTY                   // FIFO EMPTY indicator
);

    // Declare FIFO storage array and pointers
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];  // FIFO array
    reg [$clog2(FIFO_DEPTH):0] write_ptr;   // Write pointer
    reg [$clog2(FIFO_DEPTH):0] read_ptr;    // Read pointer
    reg [$clog2(FIFO_DEPTH):0] fifo_count;  // Data count

    // FULL indicator
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            FULL <= 1'b0;
        end else begin
            FULL <= (fifo_count == FIFO_DEPTH);
        end
    end

    // EMPTY indicator
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            EMPTY <= 1'b1;
        end else begin
            EMPTY <= (fifo_count == 0);
        end
    end

    // Write logic
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            write_ptr <= 1'b0;
        end else if (WR_EN && !FULL && !RD_EN) begin
            mem[write_ptr] <= DIN;
            write_ptr <= (write_ptr == FIFO_DEPTH-1) ? 0 : (write_ptr + 1);
        end
    end

    // Read logic
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            read_ptr <= 1'b0;
            DOUT <= 0;
        end else if (RD_EN && !EMPTY && !WR_EN) begin
            DOUT <= mem[read_ptr];
            read_ptr <= (read_ptr == FIFO_DEPTH-1) ? 0 : (read_ptr + 1);
        end
    end

    // FIFO count logic
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            fifo_count <= 0;
        end else begin
            case ({WR_EN, RD_EN})
                2'b10: if (!FULL) fifo_count <= fifo_count + 1;     // Write
                2'b01: if (!EMPTY) fifo_count <= fifo_count - 1;    // Read
                default: ;                                          // Default: no change
            endcase
        end
    end

endmodule


module multiple_fifos #(
    parameter DATA_WIDTH = 8,                       // Data width
    parameter FIFO_DEPTH = 16,                      // FIFO depth
    parameter NUM_FIFOS = 4                         // FIFO number
)(
    input wire CLK,
    input wire RST_N,
    input wire [NUM_FIFOS-1:0] WR_EN,               // Write enable signal
    input wire [NUM_FIFOS-1:0] RD_EN,               // Read enable signal
    input wire [NUM_FIFOS*DATA_WIDTH-1:0] DIN,      // Write data
    output wire [NUM_FIFOS*DATA_WIDTH-1:0] DOUT,    // Read data
    output wire [NUM_FIFOS-1:0] FULL,               // FIFO FULL indicators
    output wire [NUM_FIFOS-1:0] EMPTY               // FIFO EMPTY indicators
);

    genvar i;
    generate
        for (i=0; i<NUM_FIFOS; i=i+1) begin : fifo_instances
            fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH)
            ) fifo_inst (
                .CLK(CLK),
                .RST_N(RST_N),
                .WR_EN(WR_EN[i]),
                .RD_EN(RD_EN[i]),
                .DIN(DIN[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH]),
                .DOUT(DOUT[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH]),
                .FULL(FULL[i]),
                .EMPTY(EMPTY[i])
            );
        end
    endgenerate

endmodule
