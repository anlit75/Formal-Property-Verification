module fifo #(
    parameter DATA_WIDTH = 8,           // Data width
    parameter FIFO_DEPTH = 16           // FIFO depth
)(
    input wire clk,                     // Clock
    input wire rst_n,                   // Asynchronous reset
    input wire wr_en,                   // Write enable signal
    input wire rd_en,                   // Read enable signal
    input wire [DATA_WIDTH-1:0] din,    // Write data
    output wire [DATA_WIDTH-1:0] dout,  // Read data
    output wire full,                   // FIFO full indicator
    output wire empty                   // FIFO empty indicator
);

    // Declare FIFO storage array and pointers
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];  // FIFO array
    reg [$clog2(FIFO_DEPTH):0] write_ptr = 0;   // Write pointer
    reg [$clog2(FIFO_DEPTH):0] read_ptr = 0;    // Read pointer
    reg [$clog2(FIFO_DEPTH):0] fifo_count = 0;  // Data count

    // Full and empty indicator
    assign full = (fifo_count == FIFO_DEPTH);
    assign empty = (fifo_count == 0);

    // Read data output
    assign dout = mem[read_ptr];

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[write_ptr] <= din;
            write_ptr[i] <= (write_ptr[i] == FIFO_DEPTH-1) ? 0 : (write_ptr[i] + 1);
        end
    end

    // Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= 0;
        end else if (rd_en && !empty) begin
            read_ptr[i] <= (read_ptr[i] == FIFO_DEPTH-1) ? 0 : (read_ptr[i] + 1);
        end
    end

    // FIFO count logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en, rd_en})
                2'b10: if (!full) fifo_count <= fifo_count + 1;     // Write
                2'b01: if (!empty) fifo_count <= fifo_count - 1;    // Read
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
    input wire clk,
    input wire rst_n,
    input wire [NUM_FIFOS-1:0] wr_en,               // Write enable signal
    input wire [NUM_FIFOS-1:0] rd_en,               // Read enable signal
    input wire [NUM_FIFOS*DATA_WIDTH-1:0] din,      // Write data
    output wire [NUM_FIFOS*DATA_WIDTH-1:0] dout,    // Read data
    output wire [NUM_FIFOS-1:0] full,               // FIFO full indicators
    output wire [NUM_FIFOS-1:0] empty               // FIFO empty indicators
);

    genvar i;
    generate
        for (i=0; i<NUM_FIFOS; i=i+1) begin : fifo_instances
            fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .FIFO_DEPTH(FIFO_DEPTH)
            ) fifo_inst (
                .clk(clk),
                .rst_n(rst_n),
                .wr_en(wr_en[i]),
                .rd_en(rd_en[i]),
                .din(din[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH]),
                .dout(dout[(i + 1) * DATA_WIDTH - 1:i * DATA_WIDTH]),
                .full(full[i]),
                .empty(empty[i])
            );
        end
    endgenerate

endmodule
