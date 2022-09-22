`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2022 05:30:55 PM
// Design Name: 
// Module Name: address_decode
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


module address_decode #(
    parameter NUM_REGS = 4
) (
    input  wire [$clog2(NUM_REGS-1)-1:0] address,
    output reg  [NUM_REGS-1:0] reg_en
);
    always@(address) begin: decoder_inst
        integer i;
        for (i=0; i<NUM_REGS; i=i+1) begin
            if (address == i) begin
                reg_en[i] = 1'b1;
            end else begin
                reg_en[i] = 1'b0;
            end
        end
    end
endmodule
