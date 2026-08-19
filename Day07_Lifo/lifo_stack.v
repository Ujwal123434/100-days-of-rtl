`timescale 1ns/1ps

module lifo_stack #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output full,
    output empty
);

    localparam PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    localparam COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1);

    reg [DATA_WIDTH-1:0] stack_mem [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] ptr;
    reg [COUNT_WIDTH-1:0] count;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    always @(posedge clk) begin

        if (rst) begin
            ptr   <= 0;
            count <= 0;
            dout  <= 0;
        end

        else begin

            if (push && pop) begin

                if (!empty) begin
                    dout <= stack_mem[ptr - 1];
                    stack_mem[ptr - 1] <= din;
                end

                else begin
                    stack_mem[ptr] <= din;
                    ptr <= ptr + 1'b1;
                    count <= count + 1'b1;
                end

            end

            else if (push) begin

                if (!full) begin
                    stack_mem[ptr] <= din;
                    ptr <= ptr + 1'b1;
                    count <= count + 1'b1;
                end

            end

            else if (pop) begin

                if (!empty) begin
                    dout <= stack_mem[ptr - 1];
                    ptr <= ptr - 1'b1;
                    count <= count - 1'b1;
                end

            end

        end
    end

endmodule