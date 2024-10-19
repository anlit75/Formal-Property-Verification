// ===============================================================================
// Module Name:    MULTI_FIFOS
// Project Name:   Formal Property Verification
// Description: 
//     This module instantiates multiple FIFO buffers, where the
//     number of FIFOs, data width, and FIFO depth can be configured
//     using parameters. Each FIFO operates independently, controlled
//     by separate write and read enable signals. The module outputs
//     individual FULL and EMPTY status indicators for each FIFO.
//
// Port Description:
//     Name           Dir   Width                        Description
//     ---------------------------------------------------------------------------
//     CLK            In    1                            System clock input
//     RST_N          In    1                            Asynchronous active-low reset
//     WR_EN          In    [NUM_FIFOS-1:0]              Write enable signals for each FIFO
//     RD_EN          In    [NUM_FIFOS-1:0]              Read enable signals for each FIFO
//     DIN            In    [NUM_FIFOS*DATA_WIDTH-1:0]   Data inputs for each FIFO
//     DOUT           Out   [NUM_FIFOS*DATA_WIDTH-1:0]   Data outputs from each FIFO
//     FULL           Out   [NUM_FIFOS-1:0]              FULL indicators for each FIFO
//     EMPTY          Out   [NUM_FIFOS-1:0]              EMPTY indicators for each FIFO
//
// Parameters:
//     DATA_WIDTH     - Configurable width of the data bus for each FIFO (default is 8 bits)
//     FIFO_DEPTH     - Configurable depth of each FIFO buffer (default is 16)
//     NUM_FIFOS      - Number of independent FIFOs to instantiate (default is 4)
//
// How to Use:
//     1. Ensure the system clock (CLK) and asynchronous reset (RST_N) are connected properly.
//     2. Configure the module by setting DATA_WIDTH, FIFO_DEPTH, and NUM_FIFOS as required.
//     3. Use WR_EN and RD_EN signals to control writing to and reading from each FIFO. 
//        - Set the corresponding WR_EN bit high to write data to a FIFO. 
//        - Set the corresponding RD_EN bit high to read data from a FIFO.
//     4. Monitor the FULL and EMPTY signals for each FIFO to avoid overflow or underflow.
//     5. Example:
//          - To write to FIFO 0: Set WR_EN[0] = 1 and provide data on DIN[7:0].
//          - To read from FIFO 2: Set RD_EN[2] = 1, and the data will be available on DOUT[23:16].
//
// Dependencies: 
//     FIFO.sv
// 
// Author:         Ting-An Cheng
// Date:           2024-10-19
// Last Modified:  2024-10-19
// Version:        1.0
// 
// Revision History:
//     2024-10-19 - 1.0 - Initial release
// ===============================================================================


module MULTI_FIFOS #(
    parameter DATA_WIDTH = 8,                       // Data width
    parameter FIFO_DEPTH = 16,                      // FIFO depth
    parameter NUM_FIFOS = 4                         // FIFO number
)(
    input  wire CLK,
    input  wire RST_N,
    input  wire [NUM_FIFOS-1:0] WR_EN,               // Write enable signal
    input  wire [NUM_FIFOS-1:0] RD_EN,               // Read enable signal
    input  wire [NUM_FIFOS*DATA_WIDTH-1:0] DIN,      // Write data
    output wire [NUM_FIFOS*DATA_WIDTH-1:0] DOUT,    // Read data
    output wire [NUM_FIFOS-1:0] FULL,               // FIFO FULL indicators
    output wire [NUM_FIFOS-1:0] EMPTY               // FIFO EMPTY indicators
);

    genvar i;
    generate
        for (i=0; i<NUM_FIFOS; i=i+1) begin : fifo_instances
            FIFO #(
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
