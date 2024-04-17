module ram (
    input            clk,
    input            oe,
    input            wr,
    input [21:0]      address,
    input [15:0]      data_in,
    output [15:0] data_out,

    output [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output [1:0] O_psram_ck_n,
    inout [1:0] IO_psram_rwds,
    inout [15:0] IO_psram_dq,
    output [1:0] O_psram_reset_n,
    output [1:0] O_psram_cs_n,

    output c1,
    output c2
);

localparam FREQ = 74_250_000;      // Matches pixel clock
localparam LATENCY = 3;

wire clkout_o;
wire clkoutp_o;

assign c1 = clkout_o;
assign c2 = clkoutp_o;

Gowin_rPLL2 your_instance_name(
    .clkout(clkout_o), //output clkout
    .clkoutp(clkoutp_o), //output clkoutp
    .clkin(clk) //input clkin
);


PsramController #(
    .FREQ(FREQ),
    .LATENCY(LATENCY)
) mem_ctrl(
    .clk(clkout_o), .clk_p(clkoutp_o), .resetn(1), .read(oe), .write(wr), .byte_write(0),
    .addr(address), .din(data_in), .dout(data_out), .busy(busy),
    .O_psram_ck(O_psram_ck), .IO_psram_rwds(IO_psram_rwds), .IO_psram_dq(IO_psram_dq),
    .O_psram_cs_n(O_psram_cs_n)
);


endmodule
