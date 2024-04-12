module video_top (
    input             I_clk           , // 27MHz
    input             I_rst_n         ,
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   , // {r,g,b}
    output     [2:0]  O_tmds_data_n   
);

// Define and initialize signals
wire [11:0] ver;
wire [11:0] hor;
reg  [23:0] colors;
wire        pxClk;

// Instantiate video_controller module (assuming its definition is included or defined elsewhere)
video_controller video(
    .I_clk(I_clk),
    .I_rst_n(I_rst_n),
    .O_tmds_clk_p(O_tmds_clk_p),
    .O_tmds_clk_n(O_tmds_clk_n),
    .O_tmds_data_p(O_tmds_data_p),
    .O_tmds_data_n(O_tmds_data_n),
    .O_ver_cnt(ver),
    .O_hor_cnt(hor),
    .I_color_data(colors),
    .O_px_clk(pxClk)
);


// Color parameters
localparam WHITE   = {8'd255 , 8'd255 , 8'd255 }; // {B,G,R}
localparam YELLOW  = {8'd0   , 8'd255 , 8'd255 };
localparam CYAN    = {8'd255 , 8'd255 , 8'd0   };
localparam GREEN   = {8'd0   , 8'd255 , 8'd0   };
localparam MAGENTA = {8'd255 , 8'd0   , 8'd255 };
localparam RED     = {8'd0   , 8'd0   , 8'd255 };
localparam BLUE    = {8'd255 , 8'd0   , 8'd0   };
localparam BLACK   = {8'd0   , 8'd0   , 8'd0   };



always @(posedge pxClk or negedge I_rst_n) begin
    if(!I_rst_n) 
        colors <= 24'd0;
    else begin
        case(hor[6:4])
            3'b000: colors <= WHITE;
            3'b001: colors <= YELLOW;
            3'b010: colors <= CYAN;
            3'b011: colors <= GREEN;
            3'b100: colors <= MAGENTA;
            3'b101: colors <= RED;
            3'b110: colors <= BLUE;
            3'b111: colors <= BLACK;
            default: colors <= BLUE; // Default to black for undefined values
        endcase
    end
end

endmodule
