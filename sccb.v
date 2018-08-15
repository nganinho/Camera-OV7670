`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/14/2018 12:59:18 PM
// Design Name: 
// Module Name: sccb
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
// state define
`define IDLE 2'b00
`define STA  2'b01
`define DAT  2'b10
`define STO  2'b11

// count define
`define BIT_NUM     26
`define LOW_CNT    150 // tLOW
`define HIG_CNT    150 // tHIGH
`define RIS_CNT     15 // 150ns ( max : 300ns )
`define FAL_CNT     15 // 150ns ( max : 300ns )
`define BUF_CNT    150 // bus free
`define DAT_CNT     75 // time point that bit start to be valid on data bus.
`define HDSTA       80 // HD:STA
`define SUSTA       80 // SU:STA
`define SUSTO       80 // SU:STO 

// reg 
`define REG_NUM 56

module sccb (
    input  wire clock,
    input  wire reset,
    input  wire start,
    output reg sccb_clk,
    output reg sccb_dat
);
// clock is 100Mhz
// reset is active high
reg [1:0] state, next; // state machine
reg [8:0] count;       // clock counter
reg [3:0] reg_cnt;
reg [4:0] bit_cnt; 
reg start_;

// wire
wire start_det, start_done, dat_done, stop_done, all_reg;
wire [7:0] address = 8'h42; // for write operation
wire [7:0] offset, data;

wire [15:0] addr_dat [55:0];
assign	addr_dat[0]	    =	16'h1280;	//	COM7	Reset									
assign	addr_dat[1]	    =	16'h1280;	//	COM7	Reset									
assign	addr_dat[2]	    =	16'h1204;	//	COM7	Size	&	RGB	output						
assign	addr_dat[3]	    =	16'h1180;	//	CLKRC	Prescaler	-	Fin/(1+1) --> No prescaleer. PCLK is as XCLK							
assign	addr_dat[4]	    =	16'h0C00;	//	COM3	Lots of	stuff enable scaling all others off		
assign	addr_dat[5]	    =	16'h3E00;	//	COM14	PCLK scaling	off		
assign	addr_dat[6]	    =	16'h8C00;	//	RGB444	Set	RGB	format							
assign	addr_dat[7]	    =	16'h0400;	//	COM1	no CCIR601								
assign	addr_dat[8]	    =	16'h4010;	//	COM15	Full 0-255 output RGB 565					
assign	addr_dat[9]	    =	16'h3a04;	//	TSLB	Set	UV ordering	do	not	auto-reset	window			
assign	addr_dat[10]	=	16'h1438;	//	COM9	-	AGC	Celling							
assign	addr_dat[11]	=	16'h4f40;	//	--x"4fb3"	--	MTX1	-	colour	conversion	matrix				
assign	addr_dat[12]	=	16'h5034;	//	--x"50b3"	--	MTX2	-	colour	conversion	matrix				
assign	addr_dat[13]	=	16'h510C;	//	--x"5100"	--	MTX3	-	colour	conversion	matrix				
assign	addr_dat[14]	=	16'h5217;	//	--x"523d"	--	MTX4	-	colour	conversion	matrix				
assign	addr_dat[15]	=	16'h5329;	//	--x"53a7"	--	MTX5	-	colour	conversion	matrix				
assign	addr_dat[16]	=	16'h5440;	//	--x"54e4"	--	MTX6	-	colour	conversion	matrix				
assign	addr_dat[17]	=	16'h581e;	//	--x"589e"	--	MTXS	-	Matrix	sign	and	auto	contrast		
assign	addr_dat[18]	=	16'h3dc0;	//	COM13	-	Turn on	GAMMA	and	UV	Auto	adjust		
assign	addr_dat[19]	=	16'h1180;	//	CLKRC	Prescaler	-	Fin/(1+1) --> No prescaleer. PCLK is as XCLK							
assign	addr_dat[20]	=	16'h1711;	//	HSTART	HREF	start	(high	8	bits)					
assign	addr_dat[21]	=	16'h1861;	//	HSTOP	HREF	stop	(high	8	bits)					
assign	addr_dat[22]	=	16'h32A4;	//	HREF	Edge	offset	and	low	3	bits	of	HSTART	and	HSTOP
assign	addr_dat[23]	=	16'h1903;	//	VSTART	VSYNC	start	(high	8	bits)					
assign	addr_dat[24]	=	16'h1A7b;	//	VSTOP	VSYNC	stop	(high	8	bits)					
assign	addr_dat[25]	=	16'h030a;	//	VREF	VSYNC	low	two	bits						
assign	addr_dat[26]	=	16'h0e61;	//	COM5(0x0E)	0x61									
assign	addr_dat[27]	=	16'h0f4b;	//	COM6(0x0F)	0x4B									
assign	addr_dat[28]	=	16'h1602;	//											
assign	addr_dat[29]	=	16'h1e37;	//	MVFP	(0x1E)	0x07	--	FLIP	AND	MIRROR	IMAGE	0x3x		
assign	addr_dat[30]	=	16'h2102;	//											
assign	addr_dat[31]	=	16'h2291;	//											
assign	addr_dat[32]	=	16'h2907;	//											
assign	addr_dat[33]	=	16'h330b;	//											
assign	addr_dat[34]	=	16'h350b;	//											
assign	addr_dat[35]	=	16'h371d;	//											
assign	addr_dat[36]	=	16'h3871;	//											
assign	addr_dat[37]	=	16'h392a;	//											
assign	addr_dat[38]	=	16'h3c78;	//	COM12	(0x3C)	0x78								
assign	addr_dat[39]	=	16'h4d40;	//											
assign	addr_dat[40]	=	16'h4e20;	//											
assign	addr_dat[41]	=	16'h6900;	//	GFIX	(0x69)	0x00								
assign	addr_dat[42]	=	16'h6b4a;	//											
assign	addr_dat[43]	=	16'h7410;	//											
assign	addr_dat[44]	=	16'h8d4f;	//											
assign	addr_dat[45]	=	16'h8e00;	//											
assign	addr_dat[46]	=	16'h8f00;	//											
assign	addr_dat[47]	=	16'h9000;	//											
assign	addr_dat[48]	=	16'h9100;	//											
assign	addr_dat[49]	=	16'h9600;	//											
assign	addr_dat[50]	=	16'h9a00;	//											
assign	addr_dat[51]	=	16'hb084;	//											
assign	addr_dat[52]	=	16'hb10c;	//											
assign	addr_dat[53]	=	16'hb20e;	//											
assign	addr_dat[54]	=	16'hb382;	//											
assign	addr_dat[55]	=	16'hb80a;	//											
// ----------------------------------------------
assign {offset, data}   = addr_dat[reg_cnt];

// start detection
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) start_ <= 1'b0;
    else                 start_ <= start;
end
// --------------------------------end

// control signals
// --------------------------------start
assign start_det  = ~start_ & start;
assign start_done = (state == `STA) && (  count  == (`HDSTA + `SUSTA));
assign dat_done   = (state == `DAT) && (  count  == (`LOW_CNT + `HIG_CNT + `RIS_CNT + `FAL_CNT)) && (bit_cnt == `BIT_NUM);
assign stop_done  = (state == `STO) && (  count  == (`LOW_CNT + `SUSTO + `BUF_CNT ));
assign all_reg    = (state == `STO) && ( reg_cnt == `REG_NUM );
// --------------------------------end

// state machine
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) state <= `IDLE;
    else                 state <= next;
end

// next state 
always @ (*) begin
    case ( state )
        `IDLE:  if (start_det)   next = `STA; 
                else             next = `IDLE;
        `STA:   if (start_done)  next = `DAT; 
                else             next = `STA;
        `DAT:   if (dat_done)    next = `STO; 
                else             next = `DAT; 
        `STO:   if (stop_done) begin
                    if ( ~all_reg ) next = `STA; 
                    else            next = `IDLE;
                end
                else                next = `STO;                                                
        default:                    next = `IDLE;
    endcase
end
// --------------------------------end

// counter
// --------------------------------start
always @ ( posedge clock ) begin
    if (reset == 1'b1) count <= 9'd0;
    else begin
        case ( state )
            `STA: if (count < (`SUSTA+`HDSTA))   
                                        count <= count + 9'd1;
                  else                  count <= 9'd0;
            `DAT: if (count < (`LOW_CNT + `HIG_CNT + `RIS_CNT + `FAL_CNT))
                                        count <= count + 9'd1;
                  else                  count <= 9'd0;
            `STO: if (count < (`LOW_CNT + `SUSTO + `BUF_CNT)) 
                                        count <= count + 9'd1;
                  else                  count <= 9'd0;
             default:                   count <= 9'd0;
        endcase
    end
end
// --------------------------------end
// reg_cnt logic
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) reg_cnt <= 4'd0;
    else begin 
        if (start_det)   reg_cnt <= 4'd0;
        else begin 
            if ((state == `STO) && stop_done)
               reg_cnt <= reg_cnt + 4'd1;
            else  
               reg_cnt <= reg_cnt;
        end
    end
end
// --------------------------------end

// bit_cnt logic
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) bit_cnt <= 5'd0;
    else begin
        if ((state == `DAT) && (count == `LOW_CNT + `HIG_CNT + `RIS_CNT + `FAL_CNT)) begin
            if ( bit_cnt == `BIT_NUM)   bit_cnt <= 5'd0;
            else                        bit_cnt <= bit_cnt + 5'd1;
        end
    end
end
// --------------------------------end

// sccb_clk
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) sccb_clk <= 1'b1;
    else begin
        if ( state == `DAT || state == `STO ) begin
            if (count < (`FAL_CNT + `LOW_CNT))  sccb_clk <= 1'b0;
            else                                sccb_clk <= 1'b1;
        end
    end
end
// --------------------------------end

// sccb_dat
// --------------------------------start
always @ ( posedge clock ) begin
    if ( reset == 1'b1 )
        sccb_dat  <= 1'b1; 
    else begin
        if ( state == `DAT &&  count == `DAT_CNT ) begin
            if (bit_cnt < 5'd8 )                               sccb_dat <= address[7-bit_cnt]; // address out, include access bit
            else begin
                if (bit_cnt > 5'd8 && bit_cnt < 5'd17)         sccb_dat <= offset[16-bit_cnt]; // data out
                else begin
                    if (bit_cnt > 5'd17 && bit_cnt < 5'd26)    sccb_dat <= data[25-bit_cnt]; // data out
                    else if (bit_cnt == 5'd8 || bit_cnt == 5'd17 || bit_cnt == 5'd26) 
                                                               sccb_dat <= 1'b1; // dont care bit
                end
            end
        end
        else if ( state == `STA ) begin 
                  if ( count < `SUSTA ) sccb_dat <= 1'b1;
                  else                  sccb_dat <= 1'b0;
        end
        else if ( state == `STO ) begin
                  if ( count == `DAT_CNT )                sccb_dat <= 1'b0;
                  else if ( count > (`LOW_CNT + `SUSTO))  sccb_dat <= 1'b1;
        end
    end
end
// --------------------------------end

endmodule

//         case address is
//            when x"00" => sreg <= x"1280"; -- COM7   Reset
//            when x"01" => sreg <= x"1280"; -- COM7   Reset
//            when x"02" => sreg <= x"1204"; -- COM7   Size & RGB output
//            when x"03" => sreg <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
//            when x"04" => sreg <= x"0C00"; -- COM3   Lots of stuff, enable scaling, all others off
//            when x"05" => sreg <= x"3E00"; -- COM14  PCLK scaling off
//
//            when x"06" => sreg <= x"8C00"; -- RGB444 Set RGB format
//            when x"07" => sreg <= x"0400"; -- COM1   no CCIR601
//             when x"08" => sreg <= x"4010"; -- COM15  Full 0-255 output, RGB 565
//            when x"09" => sreg <= x"3a04"; -- TSLB   Set UV ordering,  do not auto-reset window
//            when x"0A" => sreg <= x"1438"; -- COM9  - AGC Celling
//            when x"0B" => sreg <= x"4f40"; --x"4fb3"; -- MTX1  - colour conversion matrix
//            when x"0C" => sreg <= x"5034"; --x"50b3"; -- MTX2  - colour conversion matrix
//            when x"0D" => sreg <= x"510C"; --x"5100"; -- MTX3  - colour conversion matrix
//            when x"0E" => sreg <= x"5217"; --x"523d"; -- MTX4  - colour conversion matrix
//            when x"0F" => sreg <= x"5329"; --x"53a7"; -- MTX5  - colour conversion matrix
//            when x"10" => sreg <= x"5440"; --x"54e4"; -- MTX6  - colour conversion matrix
//            when x"11" => sreg <= x"581e"; --x"589e"; -- MTXS  - Matrix sign and auto contrast
//            when x"12" => sreg <= x"3dc0"; -- COM13 - Turn on GAMMA and UV Auto adjust
//            when x"13" => sreg <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
//            when x"14" => sreg <= x"1711"; -- HSTART HREF start (high 8 bits)
//            when x"15" => sreg <= x"1861"; -- HSTOP  HREF stop (high 8 bits)
//            when x"16" => sreg <= x"32A4"; -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
//            when x"17" => sreg <= x"1903"; -- VSTART VSYNC start (high 8 bits)
//            when x"18" => sreg <= x"1A7b"; -- VSTOP  VSYNC stop (high 8 bits)
//            when x"19" => sreg <= x"030a"; -- VREF   VSYNC low two bits
//            when x"1A" => sreg <= x"0e61"; -- COM5(0x0E) 0x61
//            when x"1B" => sreg <= x"0f4b"; -- COM6(0x0F) 0x4B
//            when x"1C" => sreg <= x"1602"; --
//            when x"1D" => sreg <= x"1e37"; -- MVFP (0x1E) 0x07  -- FLIP AND MIRROR IMAGE 0x3x
//            when x"1E" => sreg <= x"2102";
//            when x"1F" => sreg <= x"2291";
//            when x"20" => sreg <= x"2907";
//            when x"21" => sreg <= x"330b";
//            when x"22" => sreg <= x"350b";
//            when x"23" => sreg <= x"371d";
//            when x"24" => sreg <= x"3871";
//            when x"25" => sreg <= x"392a";
//            when x"26" => sreg <= x"3c78"; -- COM12 (0x3C) 0x78
//            when x"27" => sreg <= x"4d40";
//            when x"28" => sreg <= x"4e20";
//            when x"29" => sreg <= x"6900"; -- GFIX (0x69) 0x00
//            when x"2A" => sreg <= x"6b4a";
//            when x"2B" => sreg <= x"7410";
//            when x"2C" => sreg <= x"8d4f";
//            when x"2D" => sreg <= x"8e00";
//            when x"2E" => sreg <= x"8f00";
//            when x"2F" => sreg <= x"9000";
//            when x"30" => sreg <= x"9100";
//            when x"31" => sreg <= x"9600";
//            when x"32" => sreg <= x"9a00";
//            when x"33" => sreg <= x"b084";
//            when x"34" => sreg <= x"b10c";
//            when x"35" => sreg <= x"b20e";
//            when x"36" => sreg <= x"b382";
//            when x"37" => sreg <= x"b80a";
//            when others => sreg <= x"ffff";
