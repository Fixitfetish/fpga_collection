-------------------------------------------------------------------------------
--! @file       signed_mult.vhdl
--! @author     Fixitfetish
--! @date       03/Feb/2017
--! @version    0.10
--! @copyright  MIT License
--! @note       VHDL-1993
-------------------------------------------------------------------------------
library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--! @brief One single signed multiplication.
--!
--! The behavior is as follows
--! * vld=0  ->  result = result   # hold previous
--! * vld=1  ->  result = x*y      # multiply
--!
--! The length of the input factors is flexible.
--! The input factors are automatically resized with sign extensions bits to the
--! maximum possible factor length.
--! The maximum length of the input factors is device and implementation specific.
--!
--! The delay depends on the configuration and the underlying hardware.
--! The number pipeline stages is reported as constant at output port @link PIPESTAGES PIPESTAGES @endlink .

entity signed_mult is
generic (
  --! @brief Number of additional input registers. At least one is strongly recommended.
  --! If available the input registers within the DSP cell are used.
  NUM_INPUT_REG : natural := 1;
  --! @brief Number of additional result output registers.
  --! At least one is recommended when logic for rounding and/or clipping is enabled.
  --! Typically all output registers are implemented in logic and are not part of a DSP cell.
  NUM_OUTPUT_REG : natural := 0;
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
  clk        : in  std_logic;
  --! Reset result output (optional)
  rst        : in  std_logic := '0';
  --! Valid signal for input factors, high-active
  vld        : in  std_logic;
  --! Add/subtract , '0' -> +(x*y), '1' -> -(x*y). Subtraction is disabled by default.
  sub        : in  std_logic := '0';
  --! 1st product, 1st signed factor input
  x          : in  signed;
  --! 1st product, 2nd signed factor input
  y          : in  signed;
  --! Resulting product output (optionally rounded and clipped).
  result     : out signed;
  --! Valid signals for result output, high-active
  result_vld : out std_logic_vector(0 to 1);
  --! Result output overflow/clipping detection
  result_ovf : out std_logic_vector(0 to 1);
  --! Number of pipeline stages, constant, depends on configuration and device specific implementation
  PIPESTAGES : out natural := 0
);
begin

  assert (not OUTPUT_ROUND) or (OUTPUT_SHIFT_RIGHT/=0)
    report "WARNING signed_mult : Disabled rounding because OUTPUT_SHIFT_RIGHT is 0."
    severity warning;

end entity;

