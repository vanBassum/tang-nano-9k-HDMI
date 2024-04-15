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


parameter                        CLK_FRE  = 27;//Mhz
parameter                        UART_FRE = 115200;//Mhz



uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (I_clk ),         //clock input                          
	.rst_n                      (I_rst_n ),       //asynchronous reset input, low active 
	.rx_data                    (rx_data ),       //received serial data
	.rx_data_valid              (rx_data_valid ), //received serial data is valid
	.rx_data_ready              (rx_data_enable ),//data receiver module ready
	.rx_pin                     (uart_rx )        //serial data input                    
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (I_clk ),         //clock input
	.rst_n                      (I_rst_n ),       //asynchronous reset input, low active 
	.tx_data                    (tx_data ),       //data to send
	.tx_data_valid              (tx_data_valid ), //data to be sent is valid
	.tx_data_ready              (tx_data_ready ), //send ready
	.tx_pin                     (uart_tx )        //serial data output                     
);


reg[7:0]                         tx_data;
reg                              tx_data_valid;
wire                             tx_data_ready;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
reg                              rx_data_enable;


reg [7:0] buffer [0:7];
reg [2:0] index;
reg [2:0] send;

localparam                       IDLE       =  0;
localparam                       SEND       =  1;
localparam                       RECEIVE    =  2;
reg[3:0]                         state;


always@(posedge I_clk or negedge I_rst_n)
begin
	if(I_rst_n == 1'b0)
	begin
		state <= IDLE;
	end
	else
	case(state)

        IDLE:   
        begin
            index <= 0;
            tx_data_valid <= 0;
            state <= RECEIVE;
        end

        RECEIVE:
        begin
            rx_data_enable  <= 1;               // Enable receiver

            if(rx_data_valid) begin
                buffer[index] <= rx_data;
                if(rx_data == 8'h0A)
                begin
                    state <= SEND;
                    send <= 0;
                end
                else
                    index <= index + 1;         //TODO Overflow check
            end
        end

		SEND:
		begin

            if(tx_data_ready) begin             // Ready to send
                if(send >= index) begin
                    state <= IDLE;
                end else begin
                    tx_data <= buffer[send];
                    tx_data_valid <= 1;
                    send <= send + 1;
                end

            end else begin
                tx_data_valid <= 0;
            end
		end
		default:
			state <= IDLE;
	endcase
end










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
        colors <= {buffer[0][3:0], buffer[1][3:0], buffer[2][3:0], buffer[3][3:0], buffer[4][3:0], buffer[5][3:0]};
        /*case(hor[7:5])
            3'b000: colors <= WHITE;
            3'b001: colors <= YELLOW;
            3'b010: colors <= CYAN;
            3'b011: colors <= GREEN;
            3'b100: colors <= MAGENTA;
            3'b101: colors <= RED;
            3'b110: colors <= BLUE;
            3'b111: colors <= BLACK;
            default: colors <= BLUE; // Default to black for undefined values
        endcase*/
    end
end

endmodule
