`timescale 1ns/1ps

module modulo_n_counter #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    input  wire [WIDTH-1:0] mod_val,

    output reg  [WIDTH-1:0] count,
    output reg              tc
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            tc    <= 0;
        end
        else begin
            // Default: terminal count pulse is low
            tc <= 0;

            // Invalid modulo value
            if (mod_val == 0) begin
                count <= 0;
            end

            // Count only when enabled
            else if (en) begin

                // Terminal count reached
                if (count == mod_val - 1) begin
                    count <= 0;
                    tc    <= 1;
                end
                else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

endmodule