// ===============================================================================
// Module Name:    FIFO
// Project Name:   Formal Property Verification
// Description:
//     This module implements a simple First-In-First-Out (FIFO) buffer.
//     It provides basic FIFO functionality with configurable data width and depth,
//     using write and read enable signals to control data flow. The module
//     includes FULL and EMPTY indicators to signal the status of the FIFO.
//     This implementation ensures stable output and does not support
//     simultaneous read and write operations.
//
// Port Description:
//     Name           Dir   Width              Description
//     ---------------------------------------------------------------------------
//     CLK            In    1                  System clock input
//     RST_N          In    1                  Asynchronous reset
//     WR_EN          In    1                  Write enable; when high, data is written to FIFO
//     RD_EN          In    1                  Read enable; when high, data is read from FIFO
//     DIN            In    [DATA_WIDTH-1:0]   Data input to be stored in FIFO
//     DOUT           Out   [DATA_WIDTH-1:0]   Data output from the FIFO
//     FULL           Out   1                  Indicates when FIFO is full and cannot accept new data
//     EMPTY          Out   1                  Indicates when FIFO is empty and there is no data to read
//     ERROR_FLAGS    Out   [1:0]              Error flags: [1] Write to full, [0] Read from empty
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
//        - Set WR_EN to high and RD_EN to low, then provide data on DIN.
//        - The FIFO will write data only if it is not FULL.
//        - Check the FULL signal to avoid overwriting data.
//        - The ERROR_FLAGS[1] will assert if you try to write to a FULL FIFO.
//     4. To read data from the FIFO:
//        - Set RD_EN to high and WR_EN to low to read data from DOUT.
//        - The FIFO will provide data only if it is not EMPTY.
//        - The data on DOUT will remain stable until the next read operation or until the FIFO becomes empty.
//        - Check the EMPTY signal to avoid reading invalid data.
//        - The ERROR_FLAGS[0] will assert if you try to read from an EMPTY FIFO.
//     5. Important Notes:
//        - This FIFO does not support simultaneous read and write operations.
//        - If both WR_EN and RD_EN are set to 1, the FIFO will not perform any operation.
//        - When the FIFO becomes empty, DOUT is cleared to avoid displaying invalid data.
//        - ERROR_FLAGS will clear on the next clock cycle if the error condition is resolved.
//
// Dependencies:
//     None
//
// Author:         Ting-An Cheng
// Date:           2024-10-18
// Last Modified:  2024-10-20
// Version:        1.3
//
// Revision History:
//     2024-10-18 - 1.0 - Initial release
//     2024-10-19 - 1.1 - Modified output port to be registered
//     2024-10-20 - 1.2 - Optimize FULL and EMPTY logic to reflect status faster,
//                        and enhance DOUT stabilization
//     2024-10-20 - 1.3 - Add error flags to indicate write to full and read from empty
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
    output reg  EMPTY,                  // FIFO EMPTY indicator
    output reg  [1:0] ERROR_FLAGS       // Error flags: [1] Write to full, [0] Read from empty
);

    // Declare FIFO storage array and pointers
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];  // FIFO array
    reg [$clog2(FIFO_DEPTH):0] write_ptr;   // Write pointer
    reg [$clog2(FIFO_DEPTH):0] read_ptr;    // Read pointer
    reg [$clog2(FIFO_DEPTH):0] fifo_count;  // Data count

    // FULL indicator
    always @(*) begin
        if (!RST_N) begin
            FULL = 1'b0;
        end else begin
            FULL = (fifo_count == FIFO_DEPTH);
        end
    end

    // EMPTY indicator
    always @(*) begin
        if (!RST_N) begin
            EMPTY = 1'b1;
        end else begin
            EMPTY = (fifo_count == 0);
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
        end else if (EMPTY) begin
          	DOUT <= 0;
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

    // Error flags logic
    always @(posedge CLK or negedge RST_N) begin
        if (!RST_N) begin
            ERROR_FLAGS <= 2'b00;
        end else begin
            ERROR_FLAGS[1] <= WR_EN && FULL && !RD_EN;              // Write to full error
            ERROR_FLAGS[0] <= RD_EN && EMPTY && !WR_EN;             // Read from empty error
        end
    end

endmodule
