---------------------------------------------------------------------------------------------------
-- FILE    : cplx_stimuli4.vhdl   
-- AUTHOR  : Fixitfetish
-- DATE    : 01/May/2017
-- VERSION : 0.30
-- VHDL    : 1993
-- LICENSE : MIT License
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library baselib;
  use baselib.string_conversion_pkg.all;
  use baselib.file_io_pkg.all;
library cplxlib;
  use cplxlib.cplx_pkg.all;

use std.textio.all;

entity cplx_stimuli4 is
generic(
  SKIP_PRECEDING_LINES : natural := 0;
  GEN_INVALID : boolean := true;
  GEN_DECIMAL : boolean := true;
  GEN_FILE : string
);
port(
  clk    : in  std_logic;
  rst    : in  std_logic;
  dout1  : out cplx ;--:= cplx_reset(18,"R");
  dout2  : out cplx ;--:= cplx_reset(18,"R");
  dout3  : out cplx ;--:= cplx_reset(18,"R");
  dout4  : out cplx ;--:= cplx_reset(18,"R");
  finish : out std_logic := '0'
);
end entity;

-------------------------------------------------------------------------------

architecture sim of cplx_stimuli4 is

  file   ifile : text; -- input file

  signal finish_i : std_logic := '0';

  function to_01(i:integer) return std_logic is
  begin
    if i=0 then return '0'; else return '1'; end if;
  end function;

  procedure cplx_read(
    constant DEC : in boolean;
    variable l : inout line;
    signal dout : out cplx
  ) is
    variable v_rst, v_vld, v_ovf : integer;
    variable v_re : signed(dout.re'length-1 downto 0);
    variable v_im : signed(dout.im'length-1 downto 0);
  begin
    read(l, v_rst);
    read(l, v_vld);
    read(l, v_ovf);
    if DEC then
      dec_read(l, v_re);
      dec_read(l, v_im);
    else
      hex_read(l, v_re);
      hex_read(l, v_im);
    end if;
    dout.rst <= to_01(v_rst);
    dout.vld <= to_01(v_vld);
    dout.ovf <= to_01(v_ovf);
    dout.re <= v_re;
    dout.im <= v_im;
  end procedure;

begin
  
  finish <= finish_i;
  
  p_stimuli: process
    variable in_line  : line;
  begin
    dout1 <= cplx_reset(18,"R");
    dout2 <= cplx_reset(18,"R");
    dout3 <= cplx_reset(18,"R");
    dout4 <= cplx_reset(18,"R");
    
    file_open(ifile,GEN_FILE,READ_MODE);
    
    if SKIP_PRECEDING_LINES>=1 then
      for i in 1 to SKIP_PRECEDING_LINES loop
        readline(ifile,in_line); -- ignore line
      end loop;
    end if;
    
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    -- start reading at 4th line
    readline(ifile,in_line);
    while not endfile(ifile) loop
      -- 1st cplx 
      cplx_read(GEN_DECIMAL, in_line, dout1);
      -- 2nd cplx
      cplx_read(GEN_DECIMAL, in_line, dout2);
      -- 3rd cplx
      cplx_read(GEN_DECIMAL, in_line, dout3);
      -- 4th cplx
      cplx_read(GEN_DECIMAL, in_line, dout4);
      wait until rising_edge(clk);
      readline(ifile,in_line);
    end loop; -- stimuli loop
    
    file_close(ifile);
    report "Reading CPLX stimuli file completed." severity note;
    finish_i <= '1';
    wait until rising_edge(clk);

    wait; -- end of process
  end process;

end architecture;
