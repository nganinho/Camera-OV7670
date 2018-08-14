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
`define REG_NUM 6

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
wire [7:0] address = 8'h42;
wire [7:0] offset, data;
wire [7:0] _offset [5:0]; 
wire [7:0] _data   [5:0]; 

// offset in configuration
assign _offset[0] = 8'h33;
assign _offset[1] = 8'h2d;
assign _offset[2] = 8'hfa;
assign _offset[3] = 8'h55;
assign _offset[4] = 8'haa;
assign _offset[5] = 8'h7b;

// data in configuration
assign _data[0] = 8'haa;
assign _data[1] = 8'hff;
assign _data[2] = 8'h4a;
assign _data[3] = 8'h6b;
assign _data[4] = 8'h99;
assign _data[5] = 8'hf3;
assign data   = _data[reg_cnt];
assign offset = _offset[reg_cnt];

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
assign start_done = (state == `STA) && (  count == (`HDSTA + `SUSTA));
assign dat_done   = (state == `DAT) && (  count == (`LOW_CNT + `HIG_CNT + `RIS_CNT + `FAL_CNT)) && (bit_cnt == `BIT_NUM);
assign stop_done  = (state == `STO) && (  count == (`LOW_CNT + `SUSTO + `BUF_CNT));
assign all_reg    = (state == `STO) && (reg_cnt == `REG_NUM);
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
            if ((state == `STO) && (count == `BUF_CNT))
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
always @ ( posedge clock ) begin
    if ( reset == 1'b1 ) sccb_clk <= 1'b1;
    else begin
        if ( state == `DAT || state == `STO ) begin
            if (count < (`FAL_CNT + `LOW_CNT))  sccb_clk <= 1'b0;
            else                                sccb_clk <= 1'b1;
        end
    end
end

// sccb_dat
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

endmodule