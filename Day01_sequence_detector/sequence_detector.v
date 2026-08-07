`timescale 1ns / 1ps

module sequence_detector(
 input clk,rst,din,
 output reg detect
    );
    
     localparam S0 = 3'b000,
               S1 = 3'b001,
               S2 = 3'b010,
               S3 = 3'b011,
               S4 = 3'b100;
               
    reg [2:0] state, next_state;
    
    always@(posedge clk) begin 
       if(rst)
         state <= S1;
       else
          state <= next_state;
    end
    
    always@(*) begin 
    case(state)

            S0: begin
                if(din)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if(din)
                    next_state = S1;
                else
                    next_state = S2;
            end

            S2: begin
                if(din)
                    next_state = S3;
                else
                    next_state = S0;
            end

            S3: begin
                if(din)
                    next_state = S4;
                else
                    next_state = S2;
            end

            S4: begin
                if(din)
                    next_state = S1;
                else
                    next_state = S2;
            end

            default:
                next_state = S0;

        endcase
    
    end
    
    always @(*) begin
        if(state == S4)
            detect = 1'b1;
        else
            detect = 1'b0;
    end
    
endmodule