`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    reg din;

    wire detect;

    integer i;

  
    reg [14:0] data;

 
    sequence_detector uut(
        .clk(clk),
        .rst(rst),
        .din(din),
        .detect(detect)
    );

    
    always #5 clk = ~clk;

    initial begin

        clk = 0;
        rst = 1;
        din = 0;

        data = 15'b101101101101011;

  
        #12;
        rst = 0;

       

      
        for(i=14; i>=0; i=i-1) begin
            @(negedge clk);
            din = data[i];
        end

        #20;
        $finish;

    end

endmodule
