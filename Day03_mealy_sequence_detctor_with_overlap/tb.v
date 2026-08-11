`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    reg x;
    wire z;

  
mealy_sequence_detector_overlap dut(
        .clk(clk),
        .rst(rst),
        .x(x),
        .z(z)
    );

    always #5 clk = ~clk;

    initial begin

   
        clk = 0;
        rst = 1;
        x   = 0;

       
        #10;
        rst = 0;

        #10 x = 1;
        #10 x = 1;
        #10 x = 0;
        #10 x = 1;   

        #10 x = 1;
        #10 x = 0;
        #10 x = 1;  

        #10 x = 0;

        #10 $finish;

    end


endmodule