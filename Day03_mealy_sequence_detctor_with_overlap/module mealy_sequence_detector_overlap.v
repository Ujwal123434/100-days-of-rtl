`timescale 1ns / 1ps

module mealy_sequence_detector_overlap(
    input  clk,rst, x,
    output wire z
);

  
    localparam [3:0] S0 = 4'b0001;
    localparam [3:0] S1 = 4'b0010;
    localparam [3:0] S2 = 4'b0100;
    localparam [3:0] S3 = 4'b1000;

    reg [3:0] state;
    reg [3:0] next_state;

   
    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

  always @(*) begin
        case (state)

            S0: begin
                if (x)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if (x)
                    next_state = S2;
                else
                    next_state = S0;
            end

            S2: begin
                if (x)
                    next_state = S2;
                else
                    next_state = S3;
            end

            S3: begin
                if (x)
                    next_state = S1;
                else
                    next_state = S0;
            end

            default:
                next_state = S0;

        endcase
    end

  
    assign z = (state == S3) && x;

endmodule

