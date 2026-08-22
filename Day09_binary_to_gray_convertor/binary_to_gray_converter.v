`timescale 1ns / 1ps

module binary_gray_converter (
    input  wire [3:0] bin_in,
    input  wire [3:0] gray_in,

    output wire [3:0] gray_out,
    output wire [3:0] bin_out
);

    assign bin_out[3] = gray_in[3];
    assign bin_out[2] = bin_out[3] ^ gray_in[2];
    assign bin_out[1] = bin_out[2] ^ gray_in[1];
    assign bin_out[0] = bin_out[1] ^ gray_in[0];

   assign gray_out = bin_in ^ (bin_in >> 1);

endmodule
