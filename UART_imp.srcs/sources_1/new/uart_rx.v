module uart_rx (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_done
);

parameter CLK_PER_BIT = 434;  // For 115200 baud with 50 MHz clock

localparam IDLE         = 3'b000;
localparam START_BIT    = 3'b001;
localparam DATA_BITS    = 3'b010;
localparam STOP_BIT     = 3'b011;
localparam CLEANUP      = 3'b100;

reg [2:0] state = IDLE;
reg [15:0] clk_count = 0;
reg [2:0] bit_index = 0;
reg [7:0] rx_shift = 0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        rx_data <= 8'b0;
        rx_done <= 0;
        clk_count <= 0;
        bit_index <= 0;
        rx_shift <= 0;
    end else begin
        case (state)
            IDLE: begin
                rx_done <= 0;
                clk_count <= 0;
                bit_index <= 0;

                if (rx == 0)  // Start bit detected
                    state <= START_BIT;
            end

            START_BIT: begin
                if (clk_count == (CLK_PER_BIT / 2)) begin
                    if (rx == 0) begin
                        clk_count <= 0;
                        state <= DATA_BITS;
                    end else begin
                        state <= IDLE;  // False start
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA_BITS: begin
                if (clk_count == CLK_PER_BIT - 1) begin
                    clk_count <= 0;
                    rx_shift[bit_index] <= rx;

                    if (bit_index < 7)
                        bit_index <= bit_index + 1;
                    else begin
                        bit_index <= 0;
                        state <= STOP_BIT;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            STOP_BIT: begin
                if (clk_count == CLK_PER_BIT - 1) begin
                    rx_data <= rx_shift;
                    rx_done <= 1;
                    clk_count <= 0;
                    state <= CLEANUP;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            CLEANUP: begin
                state <= IDLE;
                rx_done <= 0;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
