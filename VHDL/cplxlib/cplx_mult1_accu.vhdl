-------------------------------------------------------------------------------
--! @file       cplx_mult1_accu.vhdl
--! @author     Fixitfetish
--! @date       30/Jan/2017
--! @version    0.50
--! @copyright  MIT License
--! @note       VHDL-1993
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library cplxlib;
  use cplxlib.cplx_pkg.all;

--! @brief Complex Multiply and Accumulate.
--! In general, this multiplier is a good choice when FPGA DSP cells shall be used.
--!
--! @image html cplx_mult1_accu.svg "" width=600px
--!
--! The behavior is as follows
--! * vld = x.vld and y.vld
--! * CLR=1  VLD=0  ->  r = undefined    # reset accumulator
--! * CLR=1  VLD=1  ->  r = +/-(x*y)     # restart accumulation
--! * CLR=0  VLD=0  ->  r = r            # hold accumulator
--! * CLR=0  VLD=1  ->  r = r +/-(x*y)   # proceed accumulation
--!
--! The length of the input factors is flexible.
--! The input factors are automatically resized with sign extensions bits to the
--! maximum possible factor length.
--! The maximum length of the input factors is device and implementation specific.
--! The size of the real and imaginary part of a complex input must be identical.
--! Without accumulation the result width in the accumulation register LSBs is
--!   W = x'length + y'length 
--! Dependent on result'length and additional N accumulation guard bits a shift
--! right is required to avoid overflow or clipping.
--!   OUTPUT_SHIFT_RIGHT = W - result'length - N
--!
--! If just multiplication and the sum of products is required but not further
--! accumulation then set CLR to constant '1'. 
--!
--! The delay depends on the configuration and the underlying hardware.
--! The number pipeline stages is reported as constant at output port PIPESTAGES.
--!
--! The Double Data Rate (DDR) clock 'clk2' input is only relevant when a DDR
--! implementation of this module is used.
--! Note that the double rate clock 'clk2' must have double the frequency of
--! system clock 'clk' and must be synchronous and related to 'clk'.

entity cplx_mult1_accu is
generic (
  --! @brief The number of summands is important to determine the number of additional
  --! guard bits (MSBs) that are required for the accumulation process. @link NUM_SUMMAND More...
  --!
  --! The setting is relevant to save logic especially when saturation/clipping
  --! and/or overflow detection is enabled.
  --! * 0 => maximum possible, not recommended (worst case, hardware dependent)
  --! * 1 => just one complex multiplication without accumulation
  --! * 2 => accumulate up to 2 complex products
  --! * 3 => accumulate up to 3 complex products
  --! * and so on ...
  --!
  --! Note that every single accumulated complex product result counts!
  NUM_SUMMAND : natural := 0;
  --! @brief Number of additional input registers in system clock domain.
  --! At least one is strongly recommended.
  --! If available the input registers within the DSP cell are used.
  NUM_INPUT_REG : natural := 1;
  --! @brief Number of additional result output registers in system clock domain.
  --! At least one is recommended when logic for rounding and/or clipping is enabled.
  --! Typically all output registers are implemented in logic and are not part of a DSP cell.
  NUM_OUTPUT_REG : natural := 0;
  --! @brief By default the overflow flags of the inputs are propagated to the
  --! output to not loose the overflow flags in processing chains.
  --! If the input overflow flags are ignored then output overflow flags only
  --! report overflows within this entity. Note that ignoring the input
  --! overflows can save a little bit of logic.
  INPUT_OVERFLOW_IGNORE : boolean := false;
  --! Number of bits by which the product/accumulator result output is shifted right
  OUTPUT_SHIFT_RIGHT : natural := 0;
  --! Supported operation modes 'R','O','N' and 'S'
  MODE : cplx_mode := "-"
);
port (
  --! Standard system clock
  clk        : in  std_logic;
  --! Optional double rate clock (only relevant when a DDR implementation is used)
  clk2       : in  std_logic := '0';
  --! @brief Clear accumulator (mark first valid input factors of accumulation sequence).
  --! If accumulation is not wanted then set constant '1'.
  clr        : in  std_logic;
  --! Add/subtract, '0'-> +(x*y), '1'-> -(x*y). Subtraction is disabled by default.
  sub        : in  std_logic := '0';
  --! first complex factor 
  x          : in  cplx;
  --! second complex factor 
  y          : in  cplx;
  --! Resulting product/accumulator output (optionally rounded and clipped)
  result     : out cplx;
  --! Number of pipeline stages, constant, depends on configuration and device specific implementation
  PIPESTAGES : out natural := 0
);
begin

  assert (x.re'length=x.im'length) and (y.re'length=y.im'length) and (result.re'length=result.im'length)
    report "ERROR in " & cplx_mult1_accu'INSTANCE_NAME & 
           " Real and imaginary components must have same size."
    severity failure;

  assert (MODE/='U' and MODE/='Z' and MODE/='I')
    report "ERROR in " & cplx_mult1_accu'INSTANCE_NAME & 
           " Rounding options 'U', 'Z' and 'I' are not supported."
    severity failure;

end entity;
