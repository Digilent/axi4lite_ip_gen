`timescale 1ns / 1ps

module read_fsm (
    input clk,
    input reset,
    input  arvalid,
    output arready,
    output rvalid,
    input  rready,
    output arreg_en
);
    localparam S_AWAIT_ADDRESS = 0;
    localparam S_AWAIT_DATA = 1;
    localparam C_STATES = 2;
    reg [$clog2(C_STATES)-1:0] state = 0;
    
    always@(posedge clk) begin
        if (reset) state <= 0;
        else case (state)
            S_AWAIT_ADDRESS: begin
                state <= (arvalid) ? S_AWAIT_DATA : state;
            end
            S_AWAIT_DATA: begin
                state <= (rready) ? S_AWAIT_ADDRESS : state;
            end
            default: state <= S_AWAIT_ADDRESS;
        endcase
    end
    assign rvalid = (state == S_AWAIT_DATA);
    assign arready = (state == S_AWAIT_ADDRESS);
    assign arreg_en = (state == S_AWAIT_ADDRESS);
endmodule