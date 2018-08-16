//Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2015.2 (win64) Build 1266856 Fri Jun 26 16:35:25 MDT 2015
//Date        : Thu Aug 16 11:51:14 2018
//Host        : VN-PC006 running 64-bit Service Pack 1  (build 7601)
//Command     : generate_target pll_wrapper.bd
//Design      : pll_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module pll_wrapper
   (clk_in,
    locked,
    reset,
    sys_clk,
    xclk);
  input clk_in;
  output locked;
  input reset;
  output sys_clk;
  output xclk;

  wire clk_in;
  wire locked;
  wire reset;
  wire sys_clk;
  wire xclk;

  pll pll_i
       (.clk_in(clk_in),
        .locked(locked),
        .reset(reset),
        .sys_clk(sys_clk),
        .xclk(xclk));
endmodule
