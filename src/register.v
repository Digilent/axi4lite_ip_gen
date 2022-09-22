`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2022 02:28:31 PM
// Design Name: 
// Module Name: register
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


module base_register #(
    parameter integer DATA_WIDTH = 1,
    parameter [DATA_WIDTH-1:0] RESET_VALUE = 0
) (
    input clk,
    input reset,
    input en,
    input [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o
);
    always@(posedge clk) begin
        if (reset) begin
            data_o <= 0;
        end else if (en) begin
            data_o <= data_i;
        end else begin
            data_o <= data_o;
        end
    end
endmodule
