module video_top (
    input             I_clk           , // 27MHz
    input             I_rst_n         ,
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   , // {r,g,b}
    output     [2:0]  O_tmds_data_n   ,
    input               uart_rx       ,
    output              uart_tx       ,
    output  reg   [0:5]  led,

    output [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output [1:0] O_psram_ck_n,
    inout [1:0] IO_psram_rwds,
    inout [15:0] IO_psram_dq,
    output [1:0] O_psram_reset_n,
    output [1:0] O_psram_cs_n
);



Control control
(
	.clk(I_clk),              //clock input
	.rst_n(I_rst_n),            //asynchronous reset input, low active 
    .rx(uart_rx),
    .data(ctrl_data),
    .address(ctrl_addr),
    .wr(ctrl_wr),
    .sel(ctrl_sel)
);


wire [7:0] ctrl_data;
wire [3:0] ctrl_addr;
wire       ctrl_wr;
wire       ctrl_sel;


ram myRam1(
    .clk(ram1_clk),
    .oe(ram1_oe),
    .wr(ram1_wr),
    .address(ram1_addr),
    .data_in(ram1_din),
    .data_out(ram1_dout),

    .O_psram_ck(O_psram_ck),       // Magic ports for PSRAM to be inferred
    .O_psram_ck_n(O_psram_ck_n),
    .IO_psram_rwds(IO_psram_rwds),
    .IO_psram_dq(IO_psram_dq),
    .O_psram_reset_n(O_psram_reset_n),
    .O_psram_cs_n(O_psram_cs_n)
);

// Instantiate video_controller module (assuming its definition is included or defined elsewhere)
video_controller video(
    .I_clk(I_clk),
    .I_rst_n(I_rst_n),
    .O_tmds_clk_p(O_tmds_clk_p),
    .O_tmds_clk_n(O_tmds_clk_n),
    .O_tmds_data_p(O_tmds_data_p),
    .O_tmds_data_n(O_tmds_data_n),
    .O_ver_cnt(video_ver),
    .O_hor_cnt(video_hor),
    .I_color_data(video_color),
    .O_px_clk(video_pxClk),
    .O_blanking(video_blanking)
);


wire [11:0] video_ver;
wire [11:0] video_hor;
reg  [23:0] video_color;
wire        video_pxClk;
wire        video_blanking;
    
wire        ram1_clk;
wire        ram1_oe;
wire        ram1_wr;
wire [21:0] ram1_addr;
wire [15:0] ram1_din;
wire [15:0] ram1_dout;


assign ram1_clk     = video_blanking ? I_clk : video_pxClk;
assign ram1_oe      = video_blanking ? 0 : 1;
assign ram1_wr      = video_blanking ? ctrl_wr : 0;
assign ram1_addr    = video_blanking ? ctrl_addr : video_hor[9:6];
assign ram1_din     = {ctrl_data, 0};

always @(posedge video_pxClk) begin
    video_color <= {0, ram1_dout};
end



endmodule




