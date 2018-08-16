`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2018 08:13:17 AM
// Design Name: 
// Module Name: campix
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

// XCLK : 12.xx Mhz
// PCLK : ~50   Mhz
// VGA clock: 25.175Mhz

`define IDLE  2'b00
`define VSON  2'b01
`define VSOF  2'b10

module campix(
    input  wire clock,
    input  wire reset,
    // ov7670 interface
    input  wire pclk,
    input  wire vsync,
    input  wire href,
    input  wire [7:0] pdata,
    output wire xclk,
    output reg HSYNC,
    output reg VSYNC,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue
    );
    wire nreset, clk100m;
    wire vsync_rise, vsync_fall;
    wire lcount, pcount;
    
    reg  vsync_;
    reg [9:0] pcounter;
    reg [8:0] lcounter;
    reg [1:0] state;
    reg [11:0] rgb12bit;
    reg vga_clk, den;
    reg [7:0] pdata2;
    
    pll_wrapper pll (
        .clk_in (clock  ),
        .locked (nreset ),
        .reset  (reset  ),
        .sys_clk(clk100m),
        .xclk   (xclk   )
    );
    
    //clock div 2
    always @ ( posedge pclk ) begin
        if ( nreset == 1'b0 ) vga_clk <= 1'b0;
        else                  vga_clk <= !vga_clk;
    end
    
    // vsync delay
    always @ ( posedge vga_clk ) begin 
        if ( nreset == 1'b0 ) vsync_ <= 1'b0;
        else                  vsync_ <= vsync;
    end

    assign vsync_rise =  vsync & !vsync_;
    assign vsync_fall = !vsync &  vsync_;
    
    // state
   always @ (posedge vga_clk ) begin
       if ( nreset == 1'b0 ) state <= `IDLE;
       else begin 
           case (state)
               `IDLE:  if (vsync_rise) state <= `VSON; 
               `VSON:  if (vsync_fall) state <= `VSOF;
               `VSOF:  if (vsync_rise) state <= `VSON;
               default: state <= `IDLE;
           endcase
       end
    end
    
    assign pcount = (pcounter == 9'd784) ? 1'b1 : 1'b0; 
    assign lcount = (lcounter == 8'd510) ? 1'b1 : 1'b0;
    
    // VGA pixel counter
    always @ ( posedge vga_clk ) begin
        if ( nreset == 1'b0 )             pcounter <= 9'd0;
        else begin
            if ( vsync_rise || pcount )   pcounter <= 9'b0;
            else                          pcounter <= pcounter + 9'd1;
        end
    end
    
    // line counter
    always @ ( posedge vga_clk) begin
        if ( nreset == 1'b0 )           lcounter <= 8'd0;
        else begin
            if ( vsync_rise || lcount ) lcounter <= 8'd0;
            else if ( pcount )          lcounter <= lcounter + 8'd1;      
        end
    end
    
    // VSYNC
    always @ ( posedge vga_clk ) begin
        if ( nreset == 1'b0 )                         VSYNC <= 1'b1;
        else if ( state == `VSON && lcounter < 8'd2 ) VSYNC <= 1'b0;
    end
    // HSYNC
    always @ (posedge vga_clk ) begin
        if ( nreset == 1'b0 )        HSYNC <= 1'b1;
        else begin 
            if ( lcounter > 9'd15 )
                if ( pcounter > 10'd660 && pcounter < 10'd740 ) HSYNC <= 1'b0;
                else                                            HSYNC <= 1'b1;
            else                                                HSYNC <= 1'b1;
        end
    end
    
    // latch the data
    always @ ( posedge pclk ) begin
        if ( nreset == 1'b0 )
            pdata2 <= 8'd0;
        else 
            pdata2 <= pdata;
    end
    
    // data enable
    always @ ( posedge pclk ) begin
        if ( nreset == 1'b0 ) den <= 1'b0;  
        else 
            if (href) den <= ~den; 
            else      den <= 1'b0;
    end 
    
    // 
    always @ ( posedge pclk ) begin
        if ( nreset == 1'b0 ) rgb12bit <= 12'd0;
        else begin
            if ( den ) rgb12bit <= {pdata2[3:0], pdata}; 
        end
    end
    
    assign red   = rgb12bit[11:8];
    assign green = rgb12bit[7:4];
    assign blue   = rgb12bit[3:0];
    
endmodule