`timescale 1ns / 1ps

module priority_encoder (
    input [3:0] in,
    output reg  [1:0] code,
    output   valid
);

always @(*) begin
    casez (in)
        4'b1???: code = 2'b11;
        4'b01??: code = 2'b10;
        4'b001?: code = 2'b01;
        4'b0001: code = 2'b00;
        default: code = 2'b00;
    endcase
end

assign valid = |in;

endmodule