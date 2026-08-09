`timescale 1ns / 1ps

module sequence_detector_nooverlap(
    input  wire clk,
    input  wire rst,
    input  wire din,
    output reg  detect
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b011;
    localparam S3 = 3'b010;
    localparam S4 = 3'b110;

    reg [2:0] state, next_state;

    
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

 
    always @(*) begin

        case (state)

            S0: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S2;
            end

            S2: begin
                if (din)
                    next_state = S3;
                else
                    next_state = S0;
            end

            S3: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S4;
            end

            S4: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S0;
            end

            default:
                next_state = S0;

        endcase
    end
    
    always @(*) begin
        if (state == S4)
            detect = 1'b1;
        else
            detect = 1'b0;
    end

endmodule
