`timescale 1ns/1ps

module uart_tb;

// Clock and Reset
reg clk = 0;
reg rst = 1;

// TX interface
reg tx_start = 0;
reg [7:0] tx_data = 8'h00;
wire tx;
wire tx_busy;

// RX interface
wire [7:0] rx_data;
wire rx_done;

// Instantiate Transmitter
uart_tx #(
    .CLK_PER_BIT(434)  // 115200 baud @ 50 MHz
) uart_tx_inst (
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
);

// Instantiate Receiver
uart_rx #(
    .CLK_PER_BIT(434)
) uart_rx_inst (
    .clk(clk),
    .rst(rst),
    .rx(tx),  // loopback connection
    .rx_data(rx_data),
    .rx_done(rx_done)
);

// Clock generation (50 MHz)
always #10 clk = ~clk;

initial begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);

    // Initial state
    rst = 1;
    #50;
    rst = 0;

    // Send first byte
    #100;
    tx_data = 8'hA5;
    tx_start = 1;
    #20 tx_start = 0;

    // Wait for transmission
    wait (rx_done == 1);
    #20;

    $display("Sent byte: 0x%02X, Received byte: 0x%02X", tx_data, rx_data);

    // Send second byte
    tx_data = 8'h3C;
    tx_start = 1;
    #20 tx_start = 0;

    wait (rx_done == 1);
    #20;

    $display("Sent byte: 0x%02X, Received byte: 0x%02X", tx_data, rx_data);

    #1000;
    $finish;
end

endmodule
