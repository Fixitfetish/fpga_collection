-------------------------------------------------------------------------------
-- FILE    : ieee_extension_tb.vhdl
-- AUTHOR  : Fixitfetish
-- DATE    : 31/Oct/2016
-- VERSION : 0.2
-- VHDL    : 1993
-- LICENSE : MIT License
-------------------------------------------------------------------------------
-- Copyright (c) 2016 Fixitfetish
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
-------------------------------------------------------------------------------
library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
library fixitfetish;
 use fixitfetish.ieee_extension.all;

use std.textio.all;

entity ieee_extension_tb is
end entity;

architecture sim of ieee_extension_tb is

  file SLCU : text open WRITE_MODE IS "output/shift_left_clip_unsigned.log";
  file SLCS : text open WRITE_MODE IS "output/shift_left_clip_signed.log";
  file SRRU : text open WRITE_MODE IS "output/shift_right_round_unsigned.log";
  file SRRS : text open WRITE_MODE IS "output/shift_right_round_signed.log";

  signal clk : std_logic := '1';
  
begin

 clk <= not clk after 1 ns;

 -- shift left clip unsigned
 p_slcu : process
   constant LIN : positive := 5;
   constant LOUT : positive := 5;
   constant LIN_MIN : integer := 0;
   constant LIN_MAX : integer := 2**LIN-1;
   variable din : unsigned(LIN-1 downto 0);
   variable dout : unsigned(LOUT-1 downto 0);
   variable ovfl : std_logic;
   variable r : integer;
   variable wline : line;
 begin
   for n in 0 to LIN loop
     write(wline,string'("n=") & integer'image(n), left,6);
     write(wline,string'("  wrap,ovf  clip,ovf"));
     writeline(SLCU,wline);
     for i in LIN_MIN to LIN_MAX loop
       din := to_unsigned(i,LIN);
       write(wline, integer'image(i),right, 3); write(wline,string'(" "),right, 3);
       shift_left_clip(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>false);
       r := to_integer(dout);
       write(wline, integer'image(r) & ',' & std_logic'image(ovfl),right, 10);
       shift_left_clip(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>true);
       r := to_integer(dout);
       write(wline, integer'image(r) & ',' & std_logic'image(ovfl),right, 10);
       writeline(SLCU,wline);
       wait until rising_edge(clk);
     end loop;
     writeline(SLCU,wline);
   end loop;
   report "End shift left clip unsigned" severity failure;
   while true loop
     wait until rising_edge(clk);
   end loop;
 end process;

 -- shift left clip signed
 p_slcs : process
   constant LIN : positive := 5;
   constant LOUT : positive := 5;
   constant LIN_MIN : integer := -2**(LIN-1);
   constant LIN_MAX : integer := 2**(LIN-1)-1;
   variable din : signed(LIN-1 downto 0);
   variable dout : signed(LOUT-1 downto 0);
   variable ovfl : std_logic;
   variable r : integer;
   variable wline : line;
 begin
   for n in 0 to LIN loop
     write(wline,string'("n=") & integer'image(n), left,6);
     write(wline,string'("  wrap,ovf  clip,ovf"));
     writeline(SLCS,wline);
     for i in LIN_MIN to LIN_MAX loop
       din := to_signed(i,LIN);
       write(wline, integer'image(i),right, 3); write(wline,string'(" "),right, 3);
       shift_left_clip(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>false);
       r := to_integer(dout);
       write(wline, integer'image(r) & ',' & std_logic'image(ovfl),right, 10);
       shift_left_clip(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>true);
       r := to_integer(dout);
       write(wline, integer'image(r) & ',' & std_logic'image(ovfl),right, 10);
       writeline(SLCS,wline);
       wait until rising_edge(clk);
     end loop;
     writeline(SLCS,wline);
   end loop;
   report "End shift left clip signed" severity failure;
   while true loop
     wait until rising_edge(clk);
   end loop;
 end process;

 -- shift right round unsigned
 p_srru : process
   constant LIN : positive := 5;
   constant LOUT : positive := 5;
   constant LIN_MIN : integer := 0;
   constant LIN_MAX : integer := 2**LIN-1;
   variable din : unsigned(LIN-1 downto 0);
   variable dout : unsigned(LOUT-1 downto 0);
   variable ovfl : std_logic;
   variable clip : boolean := false;
   variable r : integer;
   variable wline : line;
 begin
   for n in 0 to LIN loop
     write(wline,string'("n=") & integer'image(n), left,6);
     write(wline,string'(" floor  near  ceil trunc infin"));
     writeline(SRRU,wline);
     for i in LIN_MIN to LIN_MAX loop
       din := to_unsigned(i,LIN);
       write(wline, integer'image(i),right, 3); write(wline,string'(" "),right, 3);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>floor);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>nearest);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>ceil);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>truncate);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>infinity);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       writeline(SRRU,wline);
       wait until rising_edge(clk);
     end loop;
     writeline(SRRU,wline);
   end loop;
   report "End shift right round unsigned" severity failure;
   while true loop
     wait until rising_edge(clk);
   end loop;
 end process;

 -- shift right round signed
 p_srrs : process
   constant LIN : positive := 5;
   constant LOUT : positive := 5;
   constant LIN_MIN : integer := -2**(LIN-1);
   constant LIN_MAX : integer := 2**(LIN-1)-1;
   variable din : signed(LIN-1 downto 0);
   variable dout : signed(LOUT-1 downto 0);
   variable ovfl : std_logic;
   variable clip : boolean := false;
   variable r : integer;
   variable wline : line;
 begin
   for n in 0 to LIN loop
     write(wline,string'("n=") & integer'image(n), left,6);
     write(wline,string'(" floor  near  ceil trunc infin"));
     writeline(SRRS,wline);
     for i in LIN_MIN to LIN_MAX loop
       din := to_signed(i,LIN);
       write(wline, integer'image(i),right, 3); write(wline,string'(" "),right, 3);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>floor);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>nearest);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>ceil);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>truncate);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       shift_right_round(din=>din, n=>n, dout=>dout, ovfl=>ovfl, clip=>clip, rnd=>infinity);
       r := to_integer(dout);
       write(wline, integer'image(r),right, 6);
       writeline(SRRS,wline);
       wait until rising_edge(clk);
     end loop;
     writeline(SRRS,wline);
   end loop;
   report "End shift right round signed" severity failure;
   while true loop
     wait until rising_edge(clk);
   end loop;
 end process;

end architecture;
