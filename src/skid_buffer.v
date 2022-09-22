`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2022 01:58:45 PM
// Design Name: 
// Module Name: skid_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module skid_buffer #(
    parameter integer DATA_WIDTH=32
) (
    input clk,
    input reset,
    output aready,
    input avalid,
    input [DATA_WIDTH-1:0] adata,
    input bready,
    output bvalid,
    output [DATA_WIDTH-1:0] bdata
);
    wire rvalid;
    wire [DATA_WIDTH-1:0] rdata;
    
    wire load;
    wire unload;
    
    assign bvalid = avalid | rvalid;
    assign bdata = rvalid ? rdata : adata;
    
    assign load = ~bready & avalid;
    assign unload = ~avalid & bready;
    
    assign aready = bready;
    
    register #(
        .DATA_WIDTH(DATA_WIDTH),
        .RESET_VALUE(0)
    ) rdata_inst (
        .clk(clk),
        .reset(reset),
        .en(load),
        .data_i(adata),
        .data_o(rdata)
    );
    
    register #(
        .DATA_WIDTH(1),
        .RESET_VALUE(0)
    ) rvalid_inst (
        .clk(clk),
        .reset(reset | unload),
        .en(load),
        .data_i(1'b1),
        .data_o(rvalid)
    );
endmodule
