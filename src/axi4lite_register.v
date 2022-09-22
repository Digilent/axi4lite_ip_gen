`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2022 05:50:41 PM
// Design Name: 
// Module Name: axi4lite_register
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


module axi4lite_register #(
    parameter integer DATA_WIDTH = 32,
    parameter [DATA_WIDTH-1:0] RESET_VALUE = 0
) (
    input                     clk,
    input                     reset,
    input                     enable,
    input  [DATA_WIDTH/8-1:0] wstrb,
    input  [DATA_WIDTH-1:0]   data_in,
    output [DATA_WIDTH-1:0]   data_out
);
    genvar i;
    generate
        for (i=0; i < DATA_WIDTH/8; i=i+1) begin
            register #(
                8,
                RESET_VALUE[i*8+:8]
            ) reg_inst (
                clk,
                reset,
                enable & wstrb[i],
                data_in[i*8+:8],
                data_out[i*8+:8]
            );
        end
    endgenerate
endmodule
