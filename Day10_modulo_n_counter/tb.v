`timescale 1ns/1ps

module tb;

    parameter WIDTH = 8;

    reg clk;
    reg rst;
    reg en;
    reg [WIDTH-1:0] mod_val;

    wire [WIDTH-1:0] count;
    wire tc;

    // DUT
    modulo_n_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .mod_val(mod_val),
        .count(count),
        .tc(tc)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    // VCD dump
    initial begin
        $dumpfile("modulo_n_counter.vcd");
        $dumpvars(0, tb);
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | rst=%b en=%b mod_val=%0d count=%0d tc=%b",
                 $time, rst, en, mod_val, count, tc);
    end

    initial begin

        // Initial values
        clk     = 0;
        rst     = 1;
        en      = 0;
        mod_val = 5;

        // Reset
        #12;
        rst = 0;

        // -----------------------------------
        // Test 1: Normal modulo-5 counting
        // -----------------------------------
        $display("\n--- TEST 1: MODULO 5 ---");

        en = 1;

        #60;

        // -----------------------------------
        // Test 2: Disable counting
        // -----------------------------------
        $display("\n--- TEST 2: ENABLE = 0 ---");

        en = 0;

        #30;

        // -----------------------------------
        // Test 3: Enable again
        // -----------------------------------
        $display("\n--- TEST 3: ENABLE = 1 ---");

        en = 1;

        #30;

        // -----------------------------------
        // Test 4: MODULO 1
        // -----------------------------------
        $display("\n--- TEST 4: MODULO 1 ---");

        mod_val = 1;

        #40;

        // -----------------------------------
        // Test 5: MODULO 0
        // -----------------------------------
        $display("\n--- TEST 5: MODULO 0 ---");

        mod_val = 0;

        #30;

        // -----------------------------------
        // Test 6: Change back to MODULO 4
        // -----------------------------------
        $display("\n--- TEST 6: MODULO 4 ---");

        mod_val = 4;

        #50;

        // Finish
        $display("\n--- SIMULATION COMPLETE ---");

        $finish;
    end

endmodule