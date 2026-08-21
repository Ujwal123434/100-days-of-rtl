`timescale 1ns / 1ps

module edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire signal_in,

    output reg rising_edge,
    output reg falling_edge
);

    reg prev;

    always @(posedge clk) begin
        if (rst) begin
            prev         <= 1'b0;
            rising_edge  <= 1'b0;
            falling_edge <= 1'b0;
        end
        else begin
            rising_edge  <= signal_in & ~prev;
            falling_edge <= ~signal_in & prev;

            prev <= signal_in;
        end
    end

endmodule