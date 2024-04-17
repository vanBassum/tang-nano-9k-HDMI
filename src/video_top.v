module video_top (
    input             I_clk           , // 27MHz
    input             I_rst_n         ,
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   , // {r,g,b}
    output     [2:0]  O_tmds_data_n   ,
    input               uart_rx       ,
    output              uart_tx       ,
    output     [0:5]  led

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
    .data_out(ram1_dout)
);

wire       ram1_clk;
wire       ram1_oe;
wire       ram1_wr;
wire [3:0] ram1_addr;
wire [7:0] ram1_din;
wire [7:0] ram1_dout;

ram myRam2(
    .clk(ram2_clk),
    .oe(ram2_oe),
    .wr(ram2_wr),
    .address(ram2_addr),
    .data_in(ram2_din),
    .data_out(ram2_dout)
);

wire       ram2_clk;
wire       ram2_oe;
wire       ram2_wr;
wire [3:0] ram2_addr;
wire [7:0] ram2_din;
wire [7:0] ram2_dout;


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
    .O_px_clk(video_pxClk)
);


wire [11:0] video_ver;
wire [11:0] video_hor;
wire [23:0] video_color;
wire        video_pxClk;

wire [7:0]  data;
wire [3:0]  video_addr;

assign video_addr = {video_hor[6:5], video_ver[6:5]};

// Sel == 1 then ram1 is on ctrl

assign ram1_clk =  ctrl_sel ? I_clk : video_pxClk;
assign ram2_clk = !ctrl_sel ? I_clk : video_pxClk;

assign ram1_wr =  ctrl_sel ? ctrl_wr : 0;
assign ram2_wr = !ctrl_sel ? ctrl_wr : 0;

assign ram1_oe =  ctrl_sel ? 0 : 1;
assign ram2_oe = !ctrl_sel ? 0 : 1;

assign ram1_addr =  ctrl_sel ? ctrl_addr : video_addr;
assign ram2_addr = !ctrl_sel ? ctrl_addr : video_addr;

assign ram1_din = ctrl_data;
assign ram2_din = ctrl_data;

assign data = ctrl_sel ? ram2_dout : ram1_dout;
assign video_color = {255, data, data};


assign led[0:2] = ram1_addr;
assign led[3:5] = ram2_addr;




endmodule
