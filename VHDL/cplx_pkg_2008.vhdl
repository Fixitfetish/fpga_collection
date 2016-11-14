-------------------------------------------------------------------------------
-- FILE    : cplx_pkg_2008.vhdl
-- AUTHOR  : Fixitfetish
-- DATE    : 14/Nov/2016
-- VERSION : 0.86
-- VHDL    : 2008
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

package cplx_pkg is

  ------------------------------------------
  -- TYPES
  ------------------------------------------

  -- general unconstrained complex type
  type cplx is
  record
    rst : std_logic; -- reset
    vld : std_logic; -- data valid
    ovf : std_logic; -- data overflow (or clipping)
    re  : signed; -- data real component ("downto" direction assumed)
    im  : signed; -- data imaginary component ("downto" direction assumed)
  end record;

  subtype cplx16 is cplx(re(15 downto 0), im(15 downto 0));
  subtype cplx18 is cplx(re(17 downto 0), im(17 downto 0));
  subtype cplx20 is cplx(re(19 downto 0), im(19 downto 0));
  subtype cplx22 is cplx(re(21 downto 0), im(21 downto 0));

  -- general unconstrained complex vector type (preferably "to" direction)
  type cplx_vector is array(integer range <>) of cplx;

  subtype cplx16_vector is cplx_vector(open)(re(15 downto 0), im(15 downto 0));
  subtype cplx18_vector is cplx_vector(open)(re(17 downto 0), im(17 downto 0));
  subtype cplx20_vector is cplx_vector(open)(re(19 downto 0), im(19 downto 0));
  subtype cplx22_vector is cplx_vector(open)(re(21 downto 0), im(21 downto 0));

  type cplx_option is (
    '-', -- don't care, use defaults
    'R', -- use reset on RE/IM (set RE=0 and IM=0)
    'O', -- enable overflow/underflow detection (by default off)
    'S', -- enable saturation/clipping (by default off)
    'D', -- round down towards minus infinity, floor (default, just remove LSBs)
    'N', -- round to nearest (standard rounding, i.e. +0.5 and then remove LSBs)
    'U', -- round up towards plus infinity, ceil
    'Z', -- round towards zero, truncate
    'I'  -- round towards plus/minus infinity, i.e. away from zero
--  'F'  -- flush, required/needed ?
--  'C'  -- clear, required/needed ?
--  'H'  -- hold last valid output data when invalid (toggle rate reduction)
  );
  
  -- Complex operations can be used with one or more the following options.
  -- Note that some options can not be combined, e.g. different rounding options.
  -- '-' -- don't care, use defaults
  -- 'R' -- use reset on RE/IM (set RE=0 and IM=0)
  -- 'O' -- enable overflow/underflow detection (by default off)
  -- 'S' -- enable saturation/clipping (by default off)
  -- 'D' -- round down towards minus infinity, floor (default, just remove LSBs)
  -- 'N' -- round to nearest (standard rounding, i.e. +0.5 and then remove LSBs)
  -- 'U' -- round up towards plus infinity, ceil
  -- 'Z' -- round towards zero, truncate
  -- 'I' -- round towards plus/minus infinity, i.e. away from zero
  type cplx_mode is array(integer range <>) of cplx_option;
  
  ------------------------------------------
  -- RESET
  ------------------------------------------

  -- get cplx reset value 
  -- RE/IM data will be 0 with option 'R', otherwise data is do-not-care
  function cplx_reset (
    w : positive range 2 to integer'high; -- RE/IM data width in bits
    m : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx;

  -- get cplx_vector reset value 
  -- RE/IM data will be 0 with option 'R', otherwise data is do-not-care
  function cplx_vector_reset (
    w : positive range 2 to integer'high; -- RE/IM data width in bits
    n : positive; -- number of vector elements
    m : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx_vector;

  -- Complex data reset on demand - to be placed into the data path
  -- supported options: 'R'
  function reset_on_demand (
    din : cplx; -- data input
    m   : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx;

  function reset_on_demand (
    din : cplx_vector; -- data input
    m   : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx_vector;

  ------------------------------------------
  -- RESIZE
  ------------------------------------------

  -- resize to given bit width (similar to NUMERIC_STD)
  -- supported options: 'R', 'O' and/or 'S'
  function resize(
    din : cplx; -- data input
    w   : positive range 2 to integer'high; -- output bit width
    m   : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx;

  -- resize to size of connected output
  -- supported options: 'R', 'O' and/or 'S'
  procedure resize (
    din  : in  cplx; -- data input
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  );

  ------------------------------------------
  -- RESIZE VECTOR
  ------------------------------------------

  -- resize each vector element to given bit width
  -- supported options: 'R', 'O' and/or 'S'
  function resize (
    din : cplx_vector; -- data input vector
    w   : positive range 2 to integer'high; -- output bit width
    m   : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx_vector;


  ------------------------------------------
  -- Basic complex arithmetic
  ------------------------------------------

  -- complex minus with overflow detection
  -- wrap only occurs when input is most-negative number
  -- (bit width of output equals the bit width of input)
  function "-" (din:cplx) return cplx;

  -- complex conjugate
  -- w=0 : output bit width is equal to the maximum input bit width
  -- w>0 : output bit width is w (includes resize)
  -- supported options: 'R', 'O' and/or 'S'
  function conj (
    din  : cplx; -- data input
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx;

  ------------------------------------------
  -- ADDITION and ACCUMULATION
  ------------------------------------------

  -- complex addition with optional clipping and overflow detection
  -- w=0 : output bit width is equal to the maximum input bit width
  -- w>0 : output bit width is w (includes resize)
  -- supported options: 'R', 'O' and/or 'S'
  function add (
    l,r  : cplx; -- left/right summand
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx;

  -- complex addition with optional clipping and overflow detection
  -- dout = l + r  (result sum is resized to size of connected output)
  -- supported options: 'R', 'O' and/or 'S'
  procedure add (
    l,r  : in  cplx; -- left/right summand
    dout : out cplx; -- data output, sum
    m    : in  cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  );

  -- complex addition with wrap and overflow detection
  -- (bit width of sum equals the max bit width of summands)
  function "+" (l,r: cplx) return cplx;

  -- sum of vector elements with optional clipping and overflow detection
  -- w=0 : output bit width is equal to input bit width
  -- w>0 : output bit width is w (includes resize)
  -- supported options: 'R', 'O' and/or 'S'
  function sum (
    din  : cplx_vector; -- data input vector
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx;

  -- sum of vector elements with optional clipping and overflow detection
  -- (sum result is resized to size of connected output)
  -- supported options: 'R', 'O' and/or 'S'
  procedure sum (
    din  : in  cplx_vector; -- data input vector
    dout : out cplx; -- data output, sum
    m    : in  cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  );

  ------------------------------------------
  -- SUBSTRACTION
  ------------------------------------------

  -- complex subtraction with optional clipping and overflow detection
  -- w=0 : output bit width is equal to the maximum input bit width
  -- w>0 : output bit width is w (includes resize)
  -- supported options: 'R', 'O' and/or 'S'
  function sub (
    l,r  : cplx; -- data input, left minuend, right subtrahend
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx;

  -- complex subtraction with optional clipping and overflow detection
  -- dout = l - r  (difference result is resized to size of connected output)
  -- supported options: 'R', 'O' and/or 'S'
  procedure sub (
    l,r  : in  cplx; -- data input, left minuend, right subtrahend
    dout : out cplx; -- data output, difference
    m    : in  cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  );

  -- complex subtraction with wrap and overflow detection
  -- (bit width of sum equals the max bit width of left minuend and right subtrahend)
  function "-" (l,r: cplx) return cplx;

  ------------------------------------------
  -- SHIFT LEFT AND SATURATE/CLIP
  ------------------------------------------

  -- complex signed shift left by n bits with optional clipping/saturation and overflow detection
  -- Result dout is resized to size of connected output.
  -- supported options: 'R', 'O' and/or 'S'
  procedure shift_left (
    din  : in  cplx; -- data input
    n    : in  natural; -- number of left shifts
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode
  );

  -- complex signed shift left by n bits with optional clipping/saturation and overflow detection
  -- The output bit width equals the input bit width.
  -- supported options: 'R', 'O' and/or 'S'
  function shift_left (
    din  : cplx; -- data input
    n    : natural; -- number of left shifts
    m    : cplx_mode:="-" -- mode
  ) return cplx;

  ------------------------------------------
  -- SHIFT RIGHT and ROUND
  ------------------------------------------

  -- complex signed shift right by n bits with optional rounding
  -- Result dout is resized to size of connected output.
  -- supported options: 'R' and/or ('D','N','U','Z' or 'I')
  procedure shift_right (
    din  : in  cplx; -- data input
    n    : in  natural; -- number of right shifts
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode
  );

  -- complex signed shift right by n bits with optional rounding
  -- The output bit width equals the input bit width.
  -- supported options: 'R' and/or ('D','N','U','Z' or 'I')
  function shift_right (
    din  : cplx; -- data input
    n    : natural; -- number of right shifts
    m    : cplx_mode:="-" -- mode
  ) return cplx;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX
  ------------------------------------------

  -- convert SLV to cplx, L = SLV'length must be even
  -- (real = L/2 LSBs, imaginary = L/2 MSBs)
  function to_cplx (
    slv : std_logic_vector; -- data input
    vld : std_logic; -- data valid
    rst : std_logic := '0' -- reset
  ) return cplx;

  -- convert SLV to cplx_vector, L = SLV'length must be a multiple of 2*n 
  -- (L/n bits per vector element : real = L/n/2 LSBs, imaginary = L/n/2 MSBs)
  function to_cplx_vector (
    slv : std_logic_vector; -- data input vector
    n   : positive; -- number of required vector elements
    vld : std_logic; -- data valid
    rst : std_logic := '0' -- reset
  ) return cplx_vector;

  ------------------------------------------
  -- CPLX to STD_LOGIC_VECTOR
  ------------------------------------------

  -- convert cplx to SLV, real=LSBs, imaginary=MSBs
  -- (output length = din.re'length + din.im'length)
  -- supported options: 'R'
  function to_slv(
    din : cplx;
    m   : cplx_mode:="-" -- mode, optional reset
  ) return std_logic_vector;

  -- convert cplx_vector to SLV (real=LSBs, imaginary=MSBs per vector element)
  -- output length = din'length * (din.re'length + din.im'length)
  -- supported options: 'R'
  function to_slv(
    din : cplx_vector;
    m   : cplx_mode:="-" -- mode, optional reset
  ) return std_logic_vector;

end package;

-------------------------------------------------------------------------------

package body cplx_pkg is

  ------------------------------------------
  -- local auxiliary
  ------------------------------------------
  
  -- check if mode includes a specific option
  function "=" (l:cplx_mode; r:cplx_option) return boolean is
    variable res : boolean := false;
  begin
    for i in l'range loop
      if l(i)=r then return true; end if;
    end loop;
    return res;
  end function;

  function max (l,r: integer) return integer is
  begin
    if l > r then return l; else return r; end if;
  end function;

 -- if x/=0 then return x
 -- if x=0  then return default
 function default_if_zero (x,dflt: integer) return integer is
 begin
   if x=0 then return dflt; else return x; end if;
 end function;

  ------------------------------------------
  -- RESET
  ------------------------------------------

  function cplx_reset (
    w : positive range 2 to integer'high; -- data RE/IM width in bits
    m : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx is
    variable dout : cplx(re(w-1 downto 0),im(w-1 downto 0));
  begin
    if m='R' then
      dout := (rst=>'1', vld|ovf=>'0', re|im=>(w-1 downto 0=>'0'));
    else
      dout := (rst=>'1', vld|ovf=>'0', re|im=>(w-1 downto 0=>'-'));
    end if;
    return dout;
  end function;

  function cplx_vector_reset (
    w : positive range 2 to integer'high; -- data RE/IM width in bits
    n : positive; -- number of vector elements
    m : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx_vector is
    variable dout : cplx_vector(0 to n-1)(re(w-1 downto 0),im(w-1 downto 0));
  begin
    for i in 0 to n-1 loop dout(i):=cplx_reset(w=>w, m=>m); end loop;
    return dout;
  end function;

  function reset_on_demand (din:cplx; m:cplx_mode:="-") return cplx is
    -- by default pass input to output
    variable dout : cplx(re(din.re'range),im(din.im'range)) := din;
  begin
    if din.rst='1' then
      dout.vld:='0'; dout.ovf:='0'; -- always reset control signals
      -- reset data only when explicitly wanted
      if m='R' then dout.re:=(din.re'range=>'0'); dout.im:=(din.im'range=>'0'); end if;
    end if;
    return dout;
  end function;

  function reset_on_demand (
    din : cplx_vector; -- data input
    m   : cplx_mode:="-" -- mode, supported options: 'R'
  ) return cplx_vector is
    variable dout : cplx_vector(din'range)(re(din(din'left).re'range),im(din(din'left).im'range));
  begin
    for i in din'range loop dout(i):=reset_on_demand(din=>din(i), m=>m); end loop; 
    return dout;
  end function;

  ------------------------------------------
  -- RESIZE
  ------------------------------------------

  function resize (
    din : cplx; -- data input
    w   : positive range 2 to integer'high; -- output bit width
    m   : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx(re(w-1 downto 0),im(w-1 downto 0));
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    if m='O' then dout.ovf := din.ovf or ovf_re or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  procedure resize (
    din  : in  cplx; -- data input
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) is
    constant LOUT : positive := dout.re'length;
  begin
    dout := resize(din=>din, w=>LOUT, m=>m);
  end procedure;

  ------------------------------------------
  -- RESIZE VECTOR
  ------------------------------------------

  function resize (
    din : cplx_vector; -- data input vector
    w   : positive range 2 to integer'high; -- output bit width
    m   : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx_vector is
    variable dout : cplx_vector(din'range)(re(w-1 downto 0),im(w-1 downto 0));
  begin
    for i in din'range loop dout(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  ------------------------------------------
  -- Basic complex arithmetic
  ------------------------------------------

  -- complex minus
  function "-" (din:cplx) return cplx is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx(re(din.re'length-1 downto 0),im(din.im'length-1 downto 0));
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- wrap only occurs when input is most-negative number
    SUB(l=>to_signed(0,din.re'length), r=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>false);
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>false);
    dout.ovf := dout.ovf or ovf_re or ovf_im; -- always with overflow detection
    dout := reset_on_demand(din=>dout, m=>"-"); -- never reset data
    return dout;
  end function;

  -- complex conjugate
  function conj (
    din  : cplx; -- data input
    w    : natural:=0; -- output bit width 
    m    : cplx_mode:="-" -- mode, supported options: 'R', 'O' and/or 'S'
  ) return cplx is
    variable ovf_re, ovf_im : std_logic;
    constant LIN_RE : positive := din.re'length;
    constant LIN_IM : positive := din.im'length;
    constant LOUT_RE : positive := default_if_zero(w, dflt=>LIN_RE); -- final output bit width
    constant LOUT_IM : positive := default_if_zero(w, dflt=>LIN_IM); -- final output bit width
    variable dout : cplx(re(LOUT_RE-1 downto 0),im(LOUT_IM-1 downto 0));
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- overflow/underflow not possible when LOUT>LIN
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S' and LOUT_RE<=LIN_RE));
    SUB(l=>to_signed(0,LIN_IM), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S' and LOUT_IM<=LIN_IM));
    if (m='O' and LOUT_RE<=LIN_RE) then dout.ovf := dout.ovf or ovf_re; end if;
    if (m='O' and LOUT_IM<=LIN_IM) then dout.ovf := dout.ovf or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  ------------------------------------------
  -- ADDITION and ACCUMULATION
  ------------------------------------------

  function add (
    l,r  : cplx; -- left/right summand
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx is
    constant LIN_RE : positive := max(l.re'length,r.re'length); -- default output length
    constant LIN_IM : positive := max(l.im'length,r.im'length); -- default output length
    constant LOUT_RE : positive := default_if_zero(w, dflt=>LIN_RE); -- final output length
    constant LOUT_IM : positive := default_if_zero(w, dflt=>LIN_IM); -- final output length
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx(re(LOUT_RE-1 downto 0),im(LOUT_IM-1 downto 0));
  begin
    -- by default merge input control signals
    dout.rst := l.rst or r.rst;
    dout.vld := l.vld and r.vld;
    dout.ovf := l.ovf or r.ovf;
    -- overflow/underflow not possible when LOUT>LIN
    ADD(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S' and LOUT_RE<=LIN_RE));
    ADD(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S' and LOUT_IM<=LIN_IM));
    if (m='O' and LOUT_RE<=LIN_RE) then dout.ovf := dout.ovf or ovf_re; end if;
    if (m='O' and LOUT_IM<=LIN_IM) then dout.ovf := dout.ovf or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  procedure add (
    l,r  : in  cplx; -- left/right summand
    dout : out cplx; -- data output, sum
    m    : in  cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) is
    constant LOUT : positive := max(dout.re'length, dout.im'length);
  begin
    dout := add(l=>l, r=>r, w=>LOUT, m=>m);
  end procedure;

  function "+" (l,r: cplx) return cplx is
    constant w : positive := max(l.re'length,r.re'length);
  begin
    return add(l=>l, r=>r, w=>w, m=>"O"); -- just overflow detection!
  end function;

  function sum (
    din  : cplx_vector; -- data input vector
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx
  is
    constant LVEC : positive := din'length; -- vector length
    constant LIN : positive := max(din(din'left).re'length,din(din'left).im'length); -- default output bit width
    constant LOUT : positive := default_if_zero(w, dflt=>LIN); -- final output bit width
    alias xdin : cplx_vector(0 to LVEC-1) is din; -- default range
    constant T : positive := LIN + LOG2CEIL(LVEC); -- width including additional accumulation bits
    variable temp : cplx(re(T-1 downto 0),im(T-1 downto 0));
  begin
    temp := resize(din=>xdin(0), w=>LIN); -- mode irrelevant, do not set any options here! 
    if LVEC>1 then
      for i in 1 to LVEC-1 loop temp:=temp+xdin(i); end loop;
    end if;
    return resize(din=>temp, w=>LOUT, m=>m);
  end function;

  procedure sum (
    din  : in  cplx_vector; -- data input vector
    dout : out cplx; -- data output, result of sum
    m    : in  cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) is
    constant LOUT : positive := max(dout.re'length, dout.im'length);
  begin
    dout := sum(din=>din, w=>LOUT, m=>m);
  end procedure;

  ------------------------------------------
  -- SUBSTRACTION
  ------------------------------------------

  -- complex subtraction with optional clipping and overflow detection
  -- d = l - r  (sum is resized to given output bit width of sum)
  function sub (
    l,r  : cplx; -- data input, left minuend, right subtrahend
    w    : natural:=0; -- output bit width
    m    : cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) return cplx is
    constant LIN_RE : positive := max(l.re'length,r.re'length); -- default output length
    constant LIN_IM : positive := max(l.im'length,r.im'length); -- default output length
    constant LOUT_RE : positive := default_if_zero(w, dflt=>LIN_RE); -- final output length
    constant LOUT_IM : positive := default_if_zero(w, dflt=>LIN_IM); -- final output length
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx(re(LOUT_RE-1 downto 0),im(LOUT_IM-1 downto 0));
  begin
    -- by default merge input control signals
    dout.rst := l.rst or r.rst;
    dout.vld := l.vld and r.vld;
    dout.ovf := l.ovf or r.ovf;
    -- overflow/underflow not possible when LOUT>LIN
    SUB(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S' and LOUT_RE<=LIN_RE));
    SUB(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S' and LOUT_IM<=LIN_IM));
    if (m='O' and LOUT_RE<=LIN_RE) then dout.ovf := dout.ovf or ovf_re; end if;
    if (m='O' and LOUT_IM<=LIN_IM) then dout.ovf := dout.ovf or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  -- complex subtraction with optional clipping and overflow detection
  -- d = l - r  (sum is resized to size of connected output)
  procedure sub (
    l,r  : in  cplx; -- data input, left minuend, right subtrahend
    dout : out cplx; -- data output, difference
    m    : in  cplx_mode:="-" -- mode, supported options: 'R','O' and/or 'S'
  ) is
    constant LOUT : positive := max(dout.re'length, dout.im'length);
  begin
    dout := sub(l=>l, r=>r, w=>LOUT, m=>m);
  end procedure;

  -- complex subtraction with wrap and overflow detection
  -- (bit width of sum equals the max bit width of left minuend and right subtrahend)
  function "-" (l,r: cplx) return cplx is
    constant w : positive := max(l.re'length,r.re'length);
  begin
    return sub(l=>l, r=>r, w=>w, m=>"O"); -- just overflow detection!
  end function;

  ------------------------------------------
  -- SHIFT LEFT AND SATURATE/CLIP
  ------------------------------------------

  -- complex signed shift left with optional clipping/saturation and overflow detection
  procedure shift_left (
    din  : in  cplx; -- data input
    n    : in  natural; -- number of left shifts
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode
  ) is
    variable ovf_re, ovf_im : std_logic;
    constant LOUT_RE : positive := dout.re'length;
    constant LOUT_IM : positive := dout.im'length;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    SHIFT_LEFT_CLIP(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SHIFT_LEFT_CLIP(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    if m='O' then dout.ovf := din.ovf or ovf_re or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
  end procedure;

  -- complex signed shift left with optional clipping/saturation and overflow detection
  function shift_left (
    din  : cplx; -- data input
    n    : natural; -- number of left shifts
    m    : cplx_mode:="-" -- mode
  ) return cplx is
    -- output size always equals input size
    constant LOUT_RE : positive := din.re'length;
    constant LOUT_IM : positive := din.im'length;
    variable dout : cplx(re(LOUT_RE-1 downto 0),im(LOUT_IM-1 downto 0));
  begin
    shift_left(din=>din, n=>n, dout=>dout, m=>m);
    return dout;
  end function;

  ------------------------------------------
  -- SHIFT RIGHT and ROUND
  ------------------------------------------

  procedure shift_right (
    din  : in  cplx; -- data input
    n    : in  natural; -- number of right shifts
    dout : out cplx; -- data output
    m    : in  cplx_mode:="-" -- mode
  ) is
    variable ovf_re, ovf_im : std_logic;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    if m='N' then
      SHIFT_RIGHT_ROUND(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, rnd=>nearest, clip=>(m='S'));
      SHIFT_RIGHT_ROUND(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, rnd=>nearest, clip=>(m='S'));
    elsif m='U' then
      SHIFT_RIGHT_ROUND(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, rnd=>ceil, clip=>(m='S'));
      SHIFT_RIGHT_ROUND(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, rnd=>ceil, clip=>(m='S'));
    elsif m='Z' then
      SHIFT_RIGHT_ROUND(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, rnd=>truncate, clip=>(m='S'));
      SHIFT_RIGHT_ROUND(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, rnd=>truncate, clip=>(m='S'));
    elsif m='I' then
      SHIFT_RIGHT_ROUND(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, rnd=>infinity, clip=>(m='S'));
      SHIFT_RIGHT_ROUND(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, rnd=>infinity, clip=>(m='S'));
    else
      -- by default standard rounding, i.e. floor
      SHIFT_RIGHT_ROUND(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, rnd=>floor, clip=>(m='S'));
      SHIFT_RIGHT_ROUND(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, rnd=>floor, clip=>(m='S'));
    end if;
    if m='O' then dout.ovf := din.ovf or ovf_re or ovf_im; end if;
    dout := reset_on_demand(din=>dout, m=>m);
  end procedure;

  function shift_right (
    din  : cplx; -- data input
    n    : natural; -- number of right shifts
    m    : cplx_mode:="-" -- mode
  ) return cplx is
    -- output size always equals input size
    constant LOUT_RE : positive := din.re'length;
    constant LOUT_IM : positive := din.im'length;
    variable dout : cplx(re(LOUT_RE-1 downto 0),im(LOUT_IM-1 downto 0));
  begin
    shift_right(din=>din, n=>n, dout=>dout, m=>m);
    return dout;
  end function;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX
  ------------------------------------------

  function to_cplx (
    slv : std_logic_vector;
    vld : std_logic;
    rst : std_logic := '0'
  ) return cplx is
    constant BITS : positive := slv'length/2;
    variable res : cplx(re(BITS-1 downto 0), im(BITS-1 downto 0));
  begin
    assert ((slv'length mod 2)=0)
      report "ERROR: to_cplx(), input std_logic_vector length must be even"
      severity failure;
    res.rst := rst;
    res.vld := vld;
    res.re  := signed(slv(  BITS-1 downto    0));
    res.im  := signed(slv(2*BITS-1 downto BITS));
    res.ovf := '0';
    return res;
  end function;

  function to_cplx_vector (
    slv : std_logic_vector;
    n   : positive;
    vld : std_logic;
    rst : std_logic := '0'
  ) return cplx_vector is
    constant BITS : integer := slv'length/n/2;
    variable res : cplx_vector(0 to n-1)(re(BITS-1 downto 0),im(BITS-1 downto 0));
  begin
    assert ((slv'length mod (2*n))=0)
      report "ERROR: to_cplx_vector(), input std_logic_vector length must be a multiple of 2*n"
      severity failure;
    for i in 0 to n-1 loop
      res(i) := to_cplx(slv(2*BITS*(i+1)-1 downto 2*BITS*i), vld=>vld, rst=>rst);
    end loop;
    return res;
  end function;

  ------------------------------------------
  -- CPLX to STD_LOGIC_VECTOR
  ------------------------------------------

  function to_slv(
    din : cplx;
    m   : cplx_mode:="-" -- mode
  ) return std_logic_vector is
    constant LRE : positive := din.re'length;
    constant LIM : positive := din.im'length;
    variable slv : std_logic_vector(LRE+LIM-1 downto 0);
  begin
    slv(    LRE-1 downto   0) := std_logic_vector(din.re);
    slv(LIM+LRE-1 downto LRE) := std_logic_vector(din.im);
    if m='R' and din.rst='1' then slv:=(others=>'0'); end if;
    return slv;
  end function;

  function to_slv(
    din : cplx_vector;
    m   : cplx_mode:="-" -- mode
  ) return std_logic_vector is
    constant N : positive := din'length;
    constant LRE : positive := din(din'left).re'length;
    constant LIM : positive := din(din'left).im'length;
    alias xdin : cplx_vector(0 to N-1)(re(LRE-1 downto 0),im(LIM-1 downto 0)) is din;
    variable slv : std_logic_vector(N*(LRE+LIM)-1 downto 0);
    variable i : natural range 0 to N := 0;
  begin
    for i in 0 to N-1 loop
      slv((i+1)*(LRE+LIM)-1 downto i*(LRE+LIM)) := to_slv(din=>xdin(i), m=>m);
    end loop;
    return slv;
  end function;

end package body;
