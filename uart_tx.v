`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire       baud_tick,

    output reg        tx,
    output reg        tx_busy
);

    reg [7:0] data_reg;
    reg [3:0] bit_count;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;

    always @(posedge clk) begin

        if (rst) begin
            state    <= IDLE;
            tx       <= 1'b1;
            tx_busy  <= 1'b0;
            data_reg <= 8'b0;
            bit_count <= 4'b0;
        end

        else begin

            case (state)

                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (baud_tick) begin
                        bit_count <= 4'd0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx <= data_reg[bit_count];

                    if (baud_tick) begin
                        if (bit_count == 4'd7) begin
                            state <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (baud_tick) begin
                        state <= IDLE;
                        tx_busy <= 1'b0;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                end

            endcase
        end
    end

endmodule