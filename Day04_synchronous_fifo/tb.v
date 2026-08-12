`timescale 1ns / 1ps

module tb;

parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 8;

reg clk;
reg rst_n;
reg wr_en;
reg rd_en;

reg [DATA_WIDTH-1:0] data_in;
wire [DATA_WIDTH-1:0] data_out;
wire empty;
wire full;

integer i;


// DUT
fifo #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .empty(empty),
    .full(full)
);


// Clock generation
always #5 clk = ~clk;


// Write task
task write_data(input [DATA_WIDTH-1:0] data);
begin
    @(negedge clk);

    if (!full) begin
        wr_en   = 1;
        data_in = data;
    end

    @(negedge clk);

    wr_en = 0;
end
endtask


// Read task
task read_data;
begin
    @(negedge clk);

    if (!empty)
        rd_en = 1;

    @(negedge clk);

    rd_en = 0;
end
endtask


// Test
initial begin

    // Initial values
    clk     = 0;
    rst_n   = 0;
    wr_en   = 0;
    rd_en   = 0;
    data_in = 0;


    // Reset
    #20;
    rst_n = 1;


    // Write FIFO_DEPTH values
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        write_data(i + 1);
    end


    


    // Read FIFO_DEPTH values
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        read_data();
    end


end


// Waveform dump
initial begin

    $dumpfile("fifo.vcd");
    $dumpvars(0, tb);

end

endmodule