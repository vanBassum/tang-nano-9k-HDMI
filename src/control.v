module Control (
    input                   clk,                // clock input
    input                   rst_n,              // synchronous reset input, active low
    input                   rx,
    output reg [7:0]        data,
    output reg [3:0]        address,
    output reg              wr,
    output reg              sel
);

parameter CLK_FREQ = 27;        // MHz
parameter UART_FREQ = 115200;   // Hz

wire [7:0] rx_data;
wire       rx_data_valid;
reg         flip;

uart_rx #(
    .CLK_FRE(CLK_FREQ),
    .BAUD_RATE(UART_FREQ)
) uart_rx_inst1 (
    .clk(clk),
    .rst_n(rst_n),
    .rx_data(rx_data),
    .rx_data_valid(rx_data_valid),
    .rx_data_ready(1),
    .rx_pin(rx)
);


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers
        {data, address, wr, sel, flip} <= 0;
    end else begin
        if (rx_data_valid) begin
            // Byte received, clock it into the RAM
            data <= rx_data;
            wr <= 1;
            flip <= 1;
        end else begin
            wr <= 0;
            if (flip) begin
                flip <= 0;
                sel <= !sel; // Flip buffers
                address <= address + 1;
            end
        end
    end
end

endmodule
