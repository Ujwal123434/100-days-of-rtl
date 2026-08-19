`timescale 1ns/1ps

module tb_lifo_stack;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 4;

    reg clk;
    reg rst;
    reg push;
    reg pop;
    reg [DATA_WIDTH-1:0] din;

    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;

    lifo_stack #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("lifo.vcd");
        $dumpvars(0, tb_lifo_stack);

        clk = 0;
        rst = 1;
        push = 0;
        pop = 0;
        din = 0;

        #10;
        rst = 0;

        #10;
        din = 8'd10;
        push = 1;

        #10;
        din = 8'd20;

        #10;
        din = 8'd30;

        #10;
        din = 8'd40;

        #10;
        push = 0;

        #10;
        pop = 1;

        #10;
        pop = 0;

        #10;
        pop = 1;

        #10;
        pop = 0;

        #10;
        pop = 1;

        #10;
        pop = 0;

        #10;
        pop = 1;

        #10;
        pop = 0;

        #10;

        $finish;
    end

endmodule