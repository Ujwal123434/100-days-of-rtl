`timescale 1ns / 1ps

module tb;

reg clk;
reg rst;
reg din;
wire detect;


sequence_detector_noovelap dut (
    .clk(clk),
    .rst(rst),
    .din(din),
    .detect(detect)
);


always #5 clk = ~clk;

task send_bit(input reg bit_value);
begin
    din = bit_value;
    #10;
end
endtask

initial begin

    clk = 0;
    rst = 1;
    din = 0;

  
    #2;
    rst = 0;


    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_bit(0);

    if (detect == 1)
        $display("PASS: 1010 detected");
    else
        $display("FAIL: 1010 not detected");


  

    send_bit(1);
    send_bit(0);

    if (detect == 0)
        $display("PASS: Second sequence not complete");
    else
        $display("FAIL");




    send_bit(1);
    send_bit(0);

    if (detect == 1)
        $display("PASS: Second 1010 detected");
    else
        $display("FAIL: Second 1010 not detected");

    #10;

    $finish;

end

endmodule
