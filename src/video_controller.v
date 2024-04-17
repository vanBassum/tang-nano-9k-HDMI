module video_controller (
    input             I_clk,            // Input clock at 27MHz
    input             I_rst_n,          // Reset signal, active low
    output            O_tmds_clk_p,     // Positive TMDS clock output
    output            O_tmds_clk_n,     // Negative TMDS clock output
    output     [2:0]  O_tmds_data_p,    // Positive TMDS data outputs
    output     [2:0]  O_tmds_data_n,
    output     [11:0] O_ver_cnt,        // Vertical counter output
    output     [11:0] O_hor_cnt,        // Horizontal counter output
    input      [23:0] I_color_data,     // Input color data
    output            O_px_clk,         // Pixel clock output
    output            O_blanking        
);

// Parameters for video timings
localparam N = 5;
localparam I_single_b = 8'd0;                 // 800x600    // 1024x768   // 1280x720    
localparam I_h_total  = 12'd1650;             // hor total time  // 12'd1056  // 12'd1344  // 12'd1650  
localparam I_h_sync   = 12'd40;               // hor sync time   // 12'd128   // 12'd136   // 12'd40    
localparam I_h_bporch = 12'd220;              // hor back porch  // 12'd88    // 12'd160   // 12'd220   
localparam I_h_res    = 12'd1280;             // hor resolution  // 12'd800   // 12'd1024  // 12'd1280  
localparam I_v_total  = 12'd750;              // ver total time  // 12'd628   // 12'd806   // 12'd750    
localparam I_v_sync   = 12'd5;                // ver sync time   // 12'd4     // 12'd6     // 12'd5     
localparam I_v_bporch = 12'd20;               // ver back porch  // 12'd23    // 12'd29    // 12'd20    
localparam I_v_res    = 12'd720;              // ver resolution  // 12'd600   // 12'd768   // 12'd720    
localparam I_hs_pol   = 1'b1;                 // HS polarity , 0:negetive ploarity，1：positive polarity
localparam I_vs_pol   = 1'b1;                 // VS polarity , 0:negetive ploarity，1：positive polarity

// Outputs for counters and pixel clock
assign O_ver_cnt = V_cnt;
assign O_hor_cnt = H_cnt;
assign O_px_clk = pix_clk;




// Internal signals and registers for video timing
reg  [11:0]   V_cnt;
reg  [11:0]   H_cnt;
wire          Pout_de_w;
wire          Pout_hs_w;
wire          Pout_vs_w;
reg  [N-1:0]  Pout_de_dn;
reg  [N-1:0]  Pout_hs_dn;
reg  [N-1:0]  Pout_vs_dn;
wire          De_pos;
wire          De_neg;
wire          Vs_pos;
reg  [11:0]   De_vcnt;
reg  [11:0]   De_hcnt;
reg  [11:0]   De_hcnt_d1;
reg  [11:0]   De_hcnt_d2;


// Counter incrementing for vertical and horizontal counters
always@(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n)
		V_cnt <= 12'd0;
	else begin
			if((V_cnt >= (I_v_total-1'b1)) && (H_cnt >= (I_h_total-1'b1)))
				V_cnt <= 12'd0;
			else if(H_cnt >= (I_h_total-1'b1))
				V_cnt <=  V_cnt + 1'b1;
			else
				V_cnt <= V_cnt;
	end
end

always @(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n)
		H_cnt <=  12'd0; 
	else if(H_cnt >= (I_h_total-1'b1))
		H_cnt <=  12'd0 ; 
	else 
		H_cnt <=  H_cnt + 1'b1 ;           
end


// Generating signals for DE, HS, and VS
assign  Pout_de_w = ((H_cnt>=(I_h_sync+I_h_bporch))&(H_cnt<=(I_h_sync+I_h_bporch+I_h_res-1'b1)))&
                    ((V_cnt>=(I_v_sync+I_v_bporch))&(V_cnt<=(I_v_sync+I_v_bporch+I_v_res-1'b1))) ;
assign  Pout_hs_w =  ~((H_cnt>=12'd0) & (H_cnt<=(I_h_sync-1'b1))) ;
assign  Pout_vs_w =  ~((V_cnt>=12'd0) & (V_cnt<=(I_v_sync-1'b1))) ;  


// Shift registers for DE, HS, and VS signals
always@(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n)
		begin
			Pout_de_dn  <= {N{1'b0}};                          
			Pout_hs_dn  <= {N{1'b1}};
			Pout_vs_dn  <= {N{1'b1}}; 
		end
	else 
		begin
			Pout_de_dn  <= {Pout_de_dn[N-2:0],Pout_de_w};                          
			Pout_hs_dn  <= {Pout_hs_dn[N-2:0],Pout_hs_w};
			Pout_vs_dn  <= {Pout_vs_dn[N-2:0],Pout_vs_w}; 
		end
end


// Generating DE, HS, and VS signals for test pattern
assign De_pos	= !Pout_de_dn[1] & Pout_de_dn[0]; //de rising edge
assign De_neg	= Pout_de_dn[1] && !Pout_de_dn[0];//de falling edge
assign Vs_pos	= !Pout_vs_dn[1] && Pout_vs_dn[0];//vs rising edge
assign tp0_de_in = Pout_de_dn[4];

// Counters for horizontal and vertical synchronization
always @(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n)
		De_hcnt <= 12'd0;
	else if (De_pos == 1'b1)
		De_hcnt <= 12'd0;
	else if (Pout_de_dn[1] == 1'b1)
		De_hcnt <= De_hcnt + 1'b1;
	else
		De_hcnt <= De_hcnt;
end

always @(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n) 
		De_vcnt <= 12'd0;
	else if (Vs_pos == 1'b1)
		De_vcnt <= 12'd0;
	else if (De_neg == 1'b1)
		De_vcnt <= De_vcnt + 1'b1;
	else
		De_vcnt <= De_vcnt;
end


// Processing input color data
always @(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n) begin
        tp0_data_r <= 0;
        tp0_data_g <= 0;
        tp0_data_b <= 0;
    end
	else begin
        tp0_data_r <= I_color_data[7:0];
        tp0_data_g <= I_color_data[15:8];
        tp0_data_b <= I_color_data[23:16];
    end
end

// Mode calculation based on vertical counter
assign I_mode = {1'b0,cnt_vs[9:8]};

// Registers for test pattern data and VS input
reg [7:0] tp0_data_r = 0;
reg [7:0] tp0_data_g = 0;
reg [7:0] tp0_data_b = 0;
reg       tp0_vs_in;
reg       tp0_hs_in;
reg       vs_r;
reg [9:0] cnt_vs;


always@(posedge pix_clk or negedge hdmi4_rst_n)
begin
	if(!hdmi4_rst_n)
		begin                        
			tp0_hs_in  <= 1'b1;
			tp0_vs_in  <= 1'b1; 
		end
	else 
		begin                         
			tp0_hs_in  <= I_hs_pol ? ~Pout_hs_dn[3] : Pout_hs_dn[3] ;
			tp0_vs_in  <= I_vs_pol ? ~Pout_vs_dn[3] : Pout_vs_dn[3] ;
		end
end


// Updating VS input based on falling edge
always@(posedge pix_clk)
begin
    vs_r<=tp0_vs_in;
end

always@(posedge pix_clk or negedge hdmi4_rst_n)
begin
    if(!hdmi4_rst_n)
        cnt_vs<=0;
    else if(vs_r && !tp0_vs_in) //vs24 falling edge
        cnt_vs<=cnt_vs+1'b1;
end 


// HDMI4 TX
wire serial_clk;
wire pll_lock;
wire hdmi4_rst_n;
wire pix_clk;


// Clock generation and synchronization
TMDS_rPLL u_tmds_rpll(
    .clkin     (I_clk     ),     //input clk 
    .clkout    (serial_clk),     //output clk 
    .lock      (pll_lock  )     //output lock
);

// Reset signal for HDMI4
assign hdmi4_rst_n = I_rst_n & pll_lock;

// Clock division
CLKDIV u_clkdiv(
    .RESETN(hdmi4_rst_n),
    .HCLKIN(serial_clk), //clk  x5
    .CLKOUT(pix_clk),    //clk  x1
    .CALIB (1'b1)
);

defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";

assign O_blanking = tp0_vs_in | tp0_hs_in;

// DVI TX instantiation
DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi4_rst_n   ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),
    .I_rgb_clk     (pix_clk       ),  //pixel clock
    .I_rgb_vs      (tp0_vs_in     ), 
    .I_rgb_hs      (tp0_hs_in     ),    
    .I_rgb_de      (tp0_de_in     ), 
    .I_rgb_r       (  tp0_data_r ),  //tp0_data_r
    .I_rgb_g       (  tp0_data_g  ),  
    .I_rgb_b       (  tp0_data_b  ),  
    .O_tmds_clk_p  (O_tmds_clk_p  ),
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);
endmodule














