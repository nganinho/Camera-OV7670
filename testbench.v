`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2018 04:02:47 PM
// Design Name: 
// Module Name: testbench
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


module testbench();

    reg clock;
    reg reset;
    reg start;
    reg [7:0] data;
    wire sccb_clk;
    wire sccb_dat;
    
    sccb dut (
        .clock (clock),
        .reset (reset),
        .start (start),
        .data  (data),
        .sccb_clk ( sccb_clk),
        .sccb_dat ( sccb_dat)
    );
    
    initial begin
        clock = 0; reset = 0; start = 0; data = 8'h78;
    end
    
    always begin
        #5; clock = ~ clock;
    end
    
    initial begin
        #101; reset = 1;
        #20;  reset = 0;
        
        #100; start = 1;
    end
    
endmodule
