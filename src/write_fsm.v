`timescale 1ns / 1ps

module write_fsm (
    input clk,
    input reset,
    input  awvalid,
    output awready,
    input  wvalid,
    output wready,
    output bvalid,
    input  bready,
    output awreg_en,
    output wreg_en
);
    localparam S_AWAIT_ADDRESS = 0;
    localparam S_AWAIT_DATA = 1;
    localparam S_AWAIT_RESP = 2;
    localparam C_STATES = 3;
    reg [$clog2(C_STATES)-1:0] state = 0;
    
    always@(posedge clk) begin
        if (reset) state <= 0;
        else case (state)
            S_AWAIT_ADDRESS: begin
                state <= (awvalid) ? S_AWAIT_DATA : state;
            end
            S_AWAIT_DATA: begin
                state <= (wvalid) ? S_AWAIT_RESP : state;
            end
            S_AWAIT_RESP: begin
                state <= (wvalid) ? S_AWAIT_ADDRESS : state;
            end
            default: state <= S_AWAIT_ADDRESS;
        endcase
    end
    assign wready = (state == S_AWAIT_DATA);
    assign awready = (state == S_AWAIT_ADDRESS);
    assign bvalid = (state == S_AWAIT_RESP);
    assign awreg_en = awready; // intermediate addresses aren't used since no data is available yet
    assign wreg_en = wvalid & wready; // do care about intermediate data states - don't set the register when data isn't available yet
endmodule