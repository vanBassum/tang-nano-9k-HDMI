module ram (
    input            clk,
    input            oe,
    input            wr,
    input [3:0]      address,
    input [7:0]      data_in,
    output reg [7:0] data_out
);

reg [7:0] ram_block [0:15];

always @(posedge clk) begin
    if(oe) begin
        data_out <= ram_block[address];
    end
    if(wr) begin
        ram_block[address] <= data_in;
    end
end

endmodule
