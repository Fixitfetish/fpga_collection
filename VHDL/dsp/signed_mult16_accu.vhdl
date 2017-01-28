-------------------------------------------------------------------------------
--! @file       signed_mult16_accu.vhdl
--! @author     Fixitfetish
--! @date       28/Jan/2017
--! @version    0.10
--! @copyright  MIT License
--! @note       VHDL-1993
-------------------------------------------------------------------------------
library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--! @brief Sixteen signed multiplications and accumulate all product results.
--! 
--! @image html signed_mult16_accu.svg "" width=600px
--!
--! The behavior is as follows
--! * CLR=1  VLD=0  ->  r = undefined                      # reset accumulator
--! * CLR=1  VLD=1  ->  r = +/-(x0*y0) +/-(x1*y1) +/-...   # restart accumulation
--! * CLR=0  VLD=0  ->  r = r                              # hold accumulator
--! * CLR=0  VLD=1  ->  r = r +/-(x0*y0) +/-(x1*y1) +/-... # proceed accumulation
--!
--! The length of the input factors is flexible.
--! The input factors are automatically resized with sign extensions bits to the
--! maximum possible factor length.
--! The maximum length of the input factors is device and implementation specific.
--! The resulting length of all products (x(n)'length + y(n)'length) must be the same.
--!
--! @image html accumulator_register.svg "" width=800px
--!
--! * ACCU WIDTH = accumulator width (device specific)
--! * PRODUCT WIDTH = x'length + y'length
--! * GUARD BITS = ceil(log2(NUM_SUMMANDS))
--! * ACCU USED WIDTH = PRODUCT WIDTH + GUARD BITS <= ACCU WIDTH
--! * OUTPUT SHIFT RIGHT = number of LSBs to prune
--! * OVFL = overflow detection sign bits, all must match the output sign bit otherwise overflow
--! * R = rounding bit (+0.5 when OUTPUT ROUND is enabled)
--! * OUTPUT WIDTH = length of result output
--! * ACCU USED SHIFTED WIDTH = ACCU USED WIDTH - OUTPUT SHIFT RIGHT
--!
--! If just the sum of products is required but not any further accumulation
--! then set CLR to constant '1'.
--!
--! The delay depends on the configuration and the underlying hardware.
--! The number pipeline stages is reported as constant at output port PIPE.
--!
--! This entity can be used for example
--!   * for multiple complex multiplications and accumulation
--!   * to calculate the mean square of complex numbers

-- Optimal settings for overflow detection and/or saturation/clipping :
-- GUARD BITS = OUTPUT WIDTH + OUTPUT SHIFT RIGHT + 1 - PRODUCT WIDTH

entity signed_mult16_accu is
generic (
  --! @brief The number of summands is important to determine the number of additional
  --! guard bits (MSBs) that are required for the accumulation process. @link NUM_SUMMAND More...
  --! 
  --! The setting is relevant to save logic especially when saturation/clipping
  --! and/or overflow detection is enabled.
  --! * 0 => maximum possible, not recommended (worst case, hardware dependent)
  --! * 1 => just one multiplication without accumulation
  --! * 2 => accumulate up to 2 products
  --! * 3 => accumulate up to 3 products
  --! *  and so on ...
  --! 
  --! Note that every single accumulated product result counts!
  NUM_SUMMAND : natural := 0;
  --! Enable chain input from neighbor DSP cell, i.e. enable additional accumulator input
  USE_CHAIN_INPUT : boolean := false;
  --! @brief Number of additional input registers. At least one is strongly recommended.
  --! If available the input registers within the DSP cell are used.
  NUM_INPUT_REG : natural := 1;
  --! @brief Additional result output register (recommended when logic for rounding and/or clipping is enabled).
  --! Typically the output register is implemented in logic. 
  OUTPUT_REG : boolean := false;
  --! Number of bits by which the accumulator result output is shifted right
  OUTPUT_SHIFT_RIGHT : natural := 0;
  --! @brief Round 'nearest' (half-up) of result output.
  --! This flag is only relevant when OUTPUT_SHIFT_RIGHT>0.
  --! If the device specific DSP cell supports rounding then rounding is done
  --! within the DSP cell. If rounding in logic is necessary then it is recommended
  --! to enable the additional output register.
  OUTPUT_ROUND : boolean := true;
  --! Enable clipping when right shifted result exceeds output range.
  OUTPUT_CLIP : boolean := true;
  --! Enable overflow/clipping detection 
  OUTPUT_OVERFLOW : boolean := true
);
port (
  --! Standard system clock
  clk      : in  std_logic;
  --! Reset result output (optional)
  rst      : in  std_logic := '0';
  --! @brief Clear accumulator (mark first valid input factors of accumulation sequence).
  --! If accumulation is not wanted then set constant '1'.
  clr      : in  std_logic;
  --! Valid signal for input factors, high-active
  vld      : in  std_logic;
  --! Add/subtract for all products n=0..15 , '0' -> +(x(n)*y(n)), '1' -> -(x(n)*y(n)). Subtraction is disabled by default.
  sub      : in  std_logic_vector(0 to 15) := (others=>'0');
  --! 1st product, 1st signed factor input
  x0       : in  signed;
  --! 1st product, 2nd signed factor input
  y0       : in  signed;
  --! 2nd product, 1st signed factor input
  x1       : in  signed;
  --! 2nd product, 2nd signed factor input
  y1       : in  signed;
  --! 3rd product, 1st signed factor input
  x2       : in  signed;
  --! 3rd product, 2nd signed factor input
  y2       : in  signed;
  --! 4th product, 1st signed factor input
  x3       : in  signed;
  --! 4th product, 2nd signed factor input
  y3       : in  signed;
  --! 5th product, 1st signed factor input
  x4       : in  signed;
  --! 5th product, 2nd signed factor input
  y4       : in  signed;
  --! 6th product, 1st signed factor input
  x5       : in  signed;
  --! 6th product, 2nd signed factor input
  y5       : in  signed;
  --! 7th product, 1st signed factor input
  x6       : in  signed;
  --! 7th product, 2nd signed factor input
  y6       : in  signed;
  --! 8th product, 1st signed factor input
  x7       : in  signed;
  --! 8th product, 2nd signed factor input
  y7       : in  signed;
  --! 1st product, 1st signed factor input
  x8       : in  signed;
  --! 1st product, 2nd signed factor input
  y8       : in  signed;
  --! 2nd product, 1st signed factor input
  x9       : in  signed;
  --! 2nd product, 2nd signed factor input
  y9       : in  signed;
  --! 3rd product, 1st signed factor input
  x10      : in  signed;
  --! 3rd product, 2nd signed factor input
  y10      : in  signed;
  --! 4th product, 1st signed factor input
  x11      : in  signed;
  --! 4th product, 2nd signed factor input
  y11      : in  signed;
  --! 5th product, 1st signed factor input
  x12      : in  signed;
  --! 5th product, 2nd signed factor input
  y12      : in  signed;
  --! 6th product, 1st signed factor input
  x13      : in  signed;
  --! 6th product, 2nd signed factor input
  y13      : in  signed;
  --! 7th product, 1st signed factor input
  x14      : in  signed;
  --! 7th product, 2nd signed factor input
  y14      : in  signed;
  --! 8th product, 1st signed factor input
  x15      : in  signed;
  --! 8th product, 2nd signed factor input
  y15      : in  signed;
  --! Valid signal for result output, high-active
  r_vld    : out std_logic;
  --! @brief Resulting product/accumulator output (optionally rounded and clipped).
  --! The standard result output might be unused when chain output is used instead.
  r_out    : out signed;
  --! Output overflow/clipping detection
  r_ovf    : out std_logic;
  --! @brief Input from other chained DSP cell (optional, only used when input enabled and connected).
  --! The chain width is device specific. A maximum width of 96 bits is supported.
  --! If the device specific chain width is smaller then only the LSBs are used.
  chainin  : in  signed(95 downto 0) := (others=>'0');
  --! @brief Result output to other chained DSP cell (optional)
  --! The chain width is device specific. A maximum width of 96 bits is supported.
  --! If the device specific chain width is smaller then only the LSBs are used.
  chainout : out signed(95 downto 0) := (others=>'0');
  --! Number of pipeline stages, constant, depends on configuration and device specific implementation
  PIPE     : out natural := 0
);
begin

  assert (     (x0'length+y0'length)=( x1'length+ y1'length)
           and (x0'length+y0'length)=( x2'length+ y2'length)
           and (x0'length+y0'length)=( x3'length+ y3'length)
           and (x0'length+y0'length)=( x4'length+ y4'length)
           and (x0'length+y0'length)=( x5'length+ y5'length)
           and (x0'length+y0'length)=( x6'length+ y6'length)
           and (x0'length+y0'length)=( x7'length+ y7'length)
           and (x0'length+y0'length)=( x8'length+ y8'length)
           and (x0'length+y0'length)=( x9'length+ y9'length)
           and (x0'length+y0'length)=(x10'length+y10'length)
           and (x0'length+y0'length)=(x11'length+y11'length)
           and (x0'length+y0'length)=(x12'length+y12'length)
           and (x0'length+y0'length)=(x13'length+y13'length)
           and (x0'length+y0'length)=(x14'length+y14'length)
           and (x0'length+y0'length)=(x15'length+y15'length) )
    report "ERROR signed_mult16_accu : All products must result in same size."
    severity failure;

  assert (not OUTPUT_ROUND) or (OUTPUT_SHIFT_RIGHT>0)
    report "WARNING signed_mult16_accu : Disabled rounding because OUTPUT_SHIFT_RIGHT is 0."
    severity warning;

end entity;
