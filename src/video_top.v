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
reg       ram1_oe;
reg       ram1_wr;
reg [3:0] ram1_addr;
reg [7:0] ram1_din;
wire [7:0] ram1_dout;


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
reg [23:0] video_color;
wire        video_pxClk;
wire        video_blanking;


reg         work;
reg [3:0]   addr;
reg [7:0]   data;

reg setWork;
reg clearWork;


always @(posedge I_clk) begin
    if(ctrl_wr == 1) begin
        setWork <= 1;
        data <= ctrl_data;
        addr <= ctrl_addr;
    end else begin
        setWork <= 0;
    end
end


assign ram1_clk = video_pxClk;

always @(posedge video_pxClk) begin
    if(video_blanking == 1) begin
        if(work == 1) begin
            ram1_wr <= 1;
            ram1_addr <= addr;
            ram1_din  <= data;
            clearWork <=1;
        end else begin
            ram1_wr <= 0;
            clearWork <=0;
        end
        ram1_oe <= 0;
    end else begin
        clearWork <=0;
        ram1_wr <= 0;
        ram1_oe <= 1;
        ram1_addr <= video_hor[8:5];
        video_color = {255, ram1_dout, ram1_dout};
    end
end


always @(posedge clearWork or posedge setWork) begin
    if(setWork) begin
        work <= 1;
    end else begin
        if(clearWork) begin
            work <= 0;
        end
    end
end


endmodule




