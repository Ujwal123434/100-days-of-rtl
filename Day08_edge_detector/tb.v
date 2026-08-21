`timescale 1ns / 1ps

module tb_edge_detector;

    reg clk;
    reg rst;
    reg signal_in;

    wire rising_edge;
    wire falling_edge;

    edge_detector uut (
        .clk(clk),
        .rst(rst),
        .signal_in(signal_in),
        .rising_edge(rising_edge),
        .falling_edge(falling_edge)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    initial begin

        clk       = 0;
        rst       = 1;
        signal_in = 0;

        // Reset
        #12;
        rst = 0;

        // 0 -> 1 : rising edge
        #8;
        signal_in = 1;

        // Keep HIGH
        #30;

        // 1 -> 0 : falling edge
        signal_in = 0;

        // Keep LOW
        #30;

        // Another rising edge
        signal_in = 1;

        #20;

        // Another falling edge
        signal_in = 0;

        #20;

        $finish;
    end

endmodule