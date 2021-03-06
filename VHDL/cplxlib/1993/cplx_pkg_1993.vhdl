-------------------------------------------------------------------------------
--! @file       cplx_pkg_1993.vhdl
--! @author     Fixitfetish
--! @date       30/Jan/2018
--! @version    1.00
--! @note       VHDL-1993
--! @copyright  <https://en.wikipedia.org/wiki/MIT_License> ,
--!             <https://opensource.org/licenses/MIT>
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library baselib;
  use baselib.ieee_extension.all;

--! @brief This package provides types, functions and procedures that allow basic
--! operations with complex integer numbers. Only the most common signals are
--! taken into account. The functions and procedures are designed in a way to
--! use as few logic elements as possible. 
--! 
--! Please note that multiplications, divisions and so on are not part of this
--! package since they typically make use of hardware specific DSP cells and
--! require registers in addition. Corresponding entities have been (or can be)
--! developed based on this package.
--!
--! NOTE: a more or less compatible complex package has been developed for VHDL-2008.
--! The VHDL-2008 version of this package is much more flexible since code duplication
--! is not required to such an extent as it is for VHDL-1993. For that reason this 
--! VHDL-1993 version only provides a subset of bit widths. But this package can be
--! easily extended to any needed bit width.
--!
package cplx_pkg is

  ------------------------------------------
  -- TYPES
  ------------------------------------------

  --! Complex 2x16 record type
  type cplx16 is
  record
    rst : std_logic; --! reset
    vld : std_logic; --! data valid
    ovf : std_logic; --! data overflow (or clipping)
    re  : signed(15 downto 0); --! data real component
    im  : signed(15 downto 0); --! data imaginary component 
  end record;

  --! Complex 2x18 record type
  type cplx18 is
  record
    rst : std_logic; --! reset
    vld : std_logic; --! data valid
    ovf : std_logic; --! data overflow (or clipping)
    re  : signed(17 downto 0); --! data real component
    im  : signed(17 downto 0); --! data imaginary component 
  end record;

  --! Complex 2x20 record type
  type cplx20 is
  record
    rst : std_logic; --! reset
    vld : std_logic; --! data valid
    ovf : std_logic; --! data overflow (or clipping)
    re  : signed(19 downto 0); --! data real component
    im  : signed(19 downto 0); --! data imaginary component 
  end record;

  --! Complex 2x22 record type
  type cplx22 is
  record
    rst : std_logic; --! reset
    vld : std_logic; --! data valid
    ovf : std_logic; --! data overflow (or clipping)
    re  : signed(21 downto 0); --! data real component
    im  : signed(21 downto 0); --! data imaginary component 
  end record;

  --! Complex 2x16 vector type (preferably "to" direction)
  type cplx16_vector is array(integer range <>) of cplx16;

  --! Complex 2x18 vector type (preferably "to" direction)
  type cplx18_vector is array(integer range <>) of cplx18;

  --! Complex 2x20 vector type (preferably "to" direction)
  type cplx20_vector is array(integer range <>) of cplx20;

  --! Complex 2x20 vector type (preferably "to" direction)
  type cplx22_vector is array(integer range <>) of cplx22;

  --! default standard complex type
  alias cplx is cplx18;

  --! default standard complex vector type
  alias cplx_vector is cplx18_vector;

  --! Definition of options
  type cplx_option is (
    '-', -- don't care, use defaults
    'D', -- round down towards minus infinity, floor (default, just remove LSBs)
    'I', -- round towards plus/minus infinity, i.e. away from zero
    'N', -- round to nearest (standard rounding, i.e. +0.5 and then remove LSBs)
    'O', -- enable overflow/underflow detection (by default off)
    'R', -- use reset on RE/IM (set RE=0 and IM=0)
    'S', -- enable saturation/clipping (by default off)
    'U', -- round up towards plus infinity, ceil
    'X', -- ignore/discard input overflow flag
    'Z'  -- round towards zero, truncate
--  'F'  -- flush, required/needed ?
--  'C'  -- clear, required/needed ?
--  'H'  -- hold last valid output data when invalid (toggle rate reduction)
  );
  
  --! @brief Complex operations can be used with one or more the following options.
  --! Note that some options can not be combined, e.g. different rounding options.
  --! Use options carefully and only when really required. Some options can have
  --! a negative influence on logic consumption and timing. @link cplx_mode More...
  --!
  --! * '-' -- don't care, use defaults
  --! * 'D' -- round down towards minus infinity, floor (default, just remove LSBs)
  --! * 'I' -- round towards plus/minus infinity, i.e. away from zero
  --! * 'N' -- round to nearest (standard rounding, i.e. +0.5 and then remove LSBs)
  --! * 'O' -- enable overflow/underflow detection (by default off)
  --! * 'R' -- use reset on RE/IM (set RE=0 and IM=0)
  --! * 'S' -- enable saturation/clipping (by default off)
  --! * 'U' -- round up towards plus infinity, ceil
  --! * 'X' -- ignore/discard input overflow flag
  --! * 'Z' -- round towards zero, truncate
  --! 
  --! Option X : By default the overflow flags of the inputs are propagated
  --! to the output to not loose the overflow flags in processing chains.
  --! If the input overflow flag is ignored in a module then output overflow
  --! flag only reports overflows that occur within the module. Note that
  --! ignoring the input overflows can save a little bit of logic.
  type cplx_mode is array(integer range <>) of cplx_option;

  ------------------------------------------
  -- auxiliary
  ------------------------------------------

  --! check if a certain option is enabled
  function "=" (l:cplx_mode; r:cplx_option) return boolean;

  --! check if a certain option is disabled
  function "/=" (l:cplx_mode; r:cplx_option) return boolean;

  ------------------------------------------
  -- RESET
  ------------------------------------------

  --! @brief Get complex reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx16;

  --! @brief Get complex vector reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits ,
  --! n = number of vector elements
  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Get complex reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx18;

  --! @brief Get complex vector reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits ,
  --! n = number of vector elements
  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Get complex reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx20;

  --! @brief Get complex vector reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits ,
  --! n = number of vector elements
  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Get complex reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx22;

  --! @brief Get complex vector reset value.
  --! RE/IM data will be 0 with option 'R', otherwise data is do-not-care.
  --! w = RE/IM data width in bits ,
  --! n = number of vector elements
  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx22_vector;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx16; m:cplx_mode:="-") return cplx16;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx16_vector; m:cplx_mode:="-") return cplx16_vector;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx18; m:cplx_mode:="-") return cplx18;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx18_vector; m:cplx_mode:="-") return cplx18_vector;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx20; m:cplx_mode:="-") return cplx20;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx20_vector; m:cplx_mode:="-") return cplx20_vector;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx22; m:cplx_mode:="-") return cplx22;

  --! Complex data reset on demand - to be placed into the data path. Supported options: 'R'
  function reset_on_demand (din:cplx22_vector; m:cplx_mode:="-") return cplx22_vector;

  ------------------------------------------
  -- RESIZE DOWN AND SATURATE/CLIP
  ------------------------------------------

  --! @brief Resize from CPLX18 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx16;

  --! @brief Resize from CPLX20 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx16;

  --! @brief Resize from CPLX22 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx16;

  --! @brief Resize from CPLX20 down to CPLX18 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx18;

  --! @brief Resize from CPLX22 down to CPLX18 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx18;

  --! @brief Resize from CPLX22 down to CPLX20 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx20;

  ------------------------------------------
  -- RESIZE DOWN VECTOR AND SATURATE/CLIP
  ------------------------------------------

  --! @brief Vector resize from CPLX18 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Vector resize from CPLX20 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Vector resize from CPLX22 down to CPLX16 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=16.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Vector resize from CPLX20 down to CPLX18 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Vector resize from CPLX22 down to CPLX18 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Vector resize from CPLX22 down to CPLX20 with optional saturation/clipping and overflow detection.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R', 'O' and/or 'S'
  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx20_vector;

  ------------------------------------------
  -- RESIZE UP
  ------------------------------------------

  --! @brief Resize from CPLX16 up to CPLX18.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R'
  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx18;

  --! @brief Resize from CPLX16 up to CPLX20.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R'
  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx20;

  --! @brief Resize from CPLX18 up to CPLX20.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R'
  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx20;

  --! @brief Resize from CPLX16 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx22;

  --! @brief Resize from CPLX18 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx22;

  --! @brief Resize from CPLX20 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx22;

  ------------------------------------------
  -- RESIZE UP VECTOR
  ------------------------------------------

  --! @brief Vector resize from CPLX16 up to CPLX18.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=18.
  --! Supported options: 'R'
  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Vector resize from CPLX16 up to CPLX20.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R'
  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Vector resize from CPLX18 up to CPLX20.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=20.
  --! Supported options: 'R'
  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Vector resize from CPLX16 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx22_vector;

  --! @brief Vector resize from CPLX18 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx22_vector;

  --! @brief Vector resize from CPLX20 up to CPLX22.
  --! To be compatible with the VHDL-2008 version of this package the output size is fixed w=22.
  --! Supported options: 'R'
  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx22_vector;

  ------------------------------------------
  -- Basic complex arithmetic
  ------------------------------------------

  --! @brief Complex negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx16) return cplx16;
  --! @brief Complex negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx18) return cplx18;
  --! @brief Complex negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx20) return cplx20;
  --! @brief Complex negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx22) return cplx22;

  --! @brief Complex vector negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx16_vector) return cplx16_vector;
  --! @brief Complex vector negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx18_vector) return cplx18_vector;
  --! @brief Complex vector negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx20_vector) return cplx20_vector;
  --! @brief Complex vector negation with overflow detection. Wrap only occurs when input is most-negative number. Bit width of output equals the bit width of input.
  function "-" (din:cplx22_vector) return cplx22_vector;

  --! @brief Complex conjugate.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function conj (din:cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16;
  function conj (din:cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Complex conjugate
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=18.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function conj (din:cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18;
  function conj (din:cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Complex conjugate
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=20.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function conj (din:cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20;
  function conj (din:cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Complex conjugate
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=22.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function conj (din:cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22;
  function conj (din:cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector;

  --! Swap real and imaginary components
  function swap (din:cplx16) return cplx16;
  function swap (din:cplx16_vector) return cplx16_vector;

  --! Swap real and imaginary components
  function swap (din:cplx18) return cplx18;
  function swap (din:cplx18_vector) return cplx18_vector;

  --! Swap real and imaginary components
  function swap (din:cplx20) return cplx20;
  function swap (din:cplx20_vector) return cplx20_vector;

  --! Swap real and imaginary components
  function swap (din:cplx22) return cplx22;
  function swap (din:cplx22_vector) return cplx22_vector;

  ------------------------------------------
  -- ADDITION and ACCUMULATION
  ------------------------------------------

  --! @brief Complex addition with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function add (l,r: cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16;
  function add (l,r: cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Complex addition with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=18.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function add (l,r: cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18;
  function add (l,r: cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Complex addition with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=20.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function add (l,r: cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20;
  function add (l,r: cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Complex addition with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=22.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function add (l,r: cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22;
  function add (l,r: cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector;

  --! Complex addition with wrap and overflow detection
  function "+" (l,r: cplx16) return cplx16;
  function "+" (l,r: cplx16_vector) return cplx16_vector;

  --! Complex addition with wrap and overflow detection
  function "+" (l,r: cplx18) return cplx18;
  function "+" (l,r: cplx18_vector) return cplx18_vector;

  --! Complex addition with wrap and overflow detection
  function "+" (l,r: cplx20) return cplx20;
  function "+" (l,r: cplx20_vector) return cplx20_vector;

  --! Complex addition with wrap and overflow detection
  function "+" (l,r: cplx22) return cplx22;
  function "+" (l,r: cplx22_vector) return cplx22_vector;

  --! @brief Sum of vector elements (max 4 elements for simplicity reasons).
  --! All inputs (i.e. vector elements) have the same bit width.
  --! The output bit width is 2 bits wider than the input bit width, i.e. w=18.
  function sum (din: cplx16_vector; w:natural:=18; m:cplx_mode:="-") return cplx18;

  --! @brief Sum of vector elements (max 4 elements for simplicity reasons).
  --! All inputs (i.e. vector elements) have the same bit width.
  --! The output bit width is 2 bits wider than the input bit width, i.e. w=20.
  function sum (din: cplx18_vector; w:natural:=20; m:cplx_mode:="-") return cplx20;

  --! @brief Sum of vector elements (max 4 elements for simplicity reasons).
  --! All inputs (i.e. vector elements) have the same bit width.
  --! The output bit width is 2 bits wider than the input bit width, i.e. w=22.
  function sum (din: cplx20_vector; w:natural:=22; m:cplx_mode:="-") return cplx22;

  ------------------------------------------
  -- SUBTRACTION
  ------------------------------------------

  --! @brief Complex subtraction with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=16.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function sub (l,r: cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16;
  function sub (l,r: cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Complex subtraction with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=18.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function sub (l,r: cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18;
  function sub (l,r: cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Complex subtraction with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=20.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function sub (l,r: cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20;
  function sub (l,r: cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Complex subtraction with optional clipping and overflow detection.
  --! Both inputs must have the same bit width.
  --! To be compatible with the VHDL-2008 version of this package the output
  --! bit width w must be equal to the input bit width, i.e. w=0 or w=22.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function sub (l,r: cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22;
  function sub (l,r: cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector;

  --! Complex subtraction with wrap and overflow detection
  function "-" (l,r: cplx16) return cplx16;
  function "-" (l,r: cplx16_vector) return cplx16_vector;

  --! Complex subtraction with wrap and overflow detection
  function "-" (l,r: cplx18) return cplx18;
  function "-" (l,r: cplx18_vector) return cplx18_vector;

  --! Complex subtraction with wrap and overflow detection
  function "-" (l,r: cplx20) return cplx20;
  function "-" (l,r: cplx20_vector) return cplx20_vector;

  --! Complex subtraction with wrap and overflow detection
  function "-" (l,r: cplx22) return cplx22;
  function "-" (l,r: cplx22_vector) return cplx22_vector;

  ------------------------------------------
  -- SHIFT LEFT AND SATURATE/CLIP
  ------------------------------------------

  --! @brief Complex signed shift left by n bits with optional clipping/saturation and overflow detection.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function shift_left (din:cplx16 ; n:natural; m:cplx_mode:="-") return cplx16;
  function shift_left (din:cplx16_vector ; n:natural; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Complex signed shift left by n bits with optional clipping/saturation and overflow detection.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function shift_left (din:cplx18 ; n:natural; m:cplx_mode:="-") return cplx18;
  function shift_left (din:cplx18_vector ; n:natural; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Complex signed shift left by n bits with optional clipping/saturation and overflow detection.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function shift_left (din:cplx20 ; n:natural; m:cplx_mode:="-") return cplx20;
  function shift_left (din:cplx20_vector ; n:natural; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Complex signed shift left by n bits with optional clipping/saturation and overflow detection.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R', 'O', 'X' and/or 'S'
  function shift_left (din:cplx22 ; n:natural; m:cplx_mode:="-") return cplx22;
  function shift_left (din:cplx22_vector ; n:natural; m:cplx_mode:="-") return cplx22_vector;

  ------------------------------------------
  -- SHIFT RIGHT and ROUND
  ------------------------------------------

  --! @brief Complex signed shift right by n bits with optional rounding.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R' and/or ('D','N','U','Z' or 'I')
  function shift_right (din:cplx16 ; n:natural; m:cplx_mode:="-") return cplx16;
  function shift_right (din:cplx16_vector ; n:natural; m:cplx_mode:="-") return cplx16_vector;

  --! @brief Complex signed shift right by n bits with optional rounding.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R' and/or ('D','N','U','Z' or 'I')
  function shift_right (din:cplx18 ; n:natural; m:cplx_mode:="-") return cplx18;
  function shift_right (din:cplx18_vector ; n:natural; m:cplx_mode:="-") return cplx18_vector;

  --! @brief Complex signed shift right by n bits with optional rounding.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R' and/or ('D','N','U','Z' or 'I')
  function shift_right (din:cplx20 ; n:natural; m:cplx_mode:="-") return cplx20;
  function shift_right (din:cplx20_vector ; n:natural; m:cplx_mode:="-") return cplx20_vector;

  --! @brief Complex signed shift right by n bits with optional rounding.
  --! The output bit width equals the input bit width.
  --! Supported options: 'R' and/or ('D','N','U','Z' or 'I')
  function shift_right (din:cplx22 ; n:natural; m:cplx_mode:="-") return cplx22;
  function shift_right (din:cplx22_vector ; n:natural; m:cplx_mode:="-") return cplx22_vector;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX
  ------------------------------------------

  --! Convert SLV to cplx16 (real = 16 LSBs, imaginary = 16 MSBs)
  function to_cplx (
    slv : std_logic_vector(31 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx16;

  --! Convert SLV to cplx18 (real = 18 LSBs, imaginary = 18 MSBs)
  function to_cplx (
    slv : std_logic_vector(35 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx18;

  --! Convert SLV to cplx20 (real = 20 LSBs, imaginary = 20 MSBs)
  function to_cplx (
    slv : std_logic_vector(39 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx20;

  --! Convert SLV to cplx22 (real = 22 LSBs, imaginary = 22 MSBs)
  function to_cplx (
    slv : std_logic_vector(43 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx22;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX VECTOR
  ------------------------------------------

  --! @brief Convert SLV to cplx16_vector, L = SLV'length must be a multiple of 32.
  --! (L/n bits per vector element : real = L/n/2 LSBs, imaginary = L/n/2 MSBs)
  function to_cplx_vector (
    slv : std_logic_vector; -- input vector (multiple of 32 bits)
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx16_vector;

  --! @brief Convert SLV to cplx18_vector, L = SLV'length must be a multiple of 36.
  --! (L/n bits per vector element : real = L/n/2 LSBs, imaginary = L/n/2 MSBs)
  function to_cplx_vector (
    slv : std_logic_vector; -- input vector (multiple of 36 bits)
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx18_vector;

  --! @brief Convert SLV to cplx20_vector, L = SLV'length must be a multiple of 40.
  --! (L/n bits per vector element : real = L/n/2 LSBs, imaginary = L/n/2 MSBs)
  function to_cplx_vector (
    slv : std_logic_vector; -- input vector (multiple of 40 bits)
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx20_vector;

  --! @brief Convert SLV to cplx22_vector, L = SLV'length must be a multiple of 44.
  --! (L/n bits per vector element : real = L/n/2 LSBs, imaginary = L/n/2 MSBs)
  function to_cplx_vector (
    slv : std_logic_vector; -- input vector (multiple of 44 bits)
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx22_vector;

  ------------------------------------------
  -- CPLX to STD_LOGIC_VECTOR
  ------------------------------------------
 
  --! @brief Convert cplx16 to SLV (real = 16 LSBs, imaginary = 16 MSBs).
  --! Supported options: 'R'
  function to_slv (din:cplx16; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx18 to SLV (real = 18 LSBs, imaginary = 18 MSBs).
  --! Supported options: 'R'
  function to_slv (din:cplx18; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx20 to SLV (real = 20 LSBs, imaginary = 20 MSBs).
  --! Supported options: 'R'
  function to_slv (din:cplx20; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx22 to SLV (real = 22 LSBs, imaginary = 22 MSBs).
  --! Supported options: 'R'
  function to_slv (din:cplx22; m:cplx_mode:="-") return std_logic_vector;

  ------------------------------------------
  -- CPLX VECTOR to STD_LOGIC_VECTOR
  ------------------------------------------

  --! @brief Convert cplx16 array to SLV (output width is 32*din'length bits).
  --! Supported options: 'R'
  function to_slv (din:cplx16_vector; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx18 array to SLV (output width is 36*din'length bits).
  --! Supported options: 'R'
  function to_slv (din:cplx18_vector; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx20 array to SLV (output width is 40*din'length bits).
  --! Supported options: 'R'
  function to_slv (din:cplx20_vector; m:cplx_mode:="-") return std_logic_vector;

  --! @brief Convert cplx22 array to SLV (output width is 44*din'length bits).
  --! Supported options: 'R'
  function to_slv (din:cplx22_vector; m:cplx_mode:="-") return std_logic_vector;

end package;

-------------------------------------------------------------------------------

package body cplx_pkg is

  ------------------------------------------
  -- auxiliary
  ------------------------------------------

  function "=" (l:cplx_mode; r:cplx_option) return boolean is
    variable res : boolean := false;
  begin
    for i in l'range loop res := res or (l(i)=r); end loop;
    return res;
  end function;

  function "/=" (l:cplx_mode; r:cplx_option) return boolean is
  begin
    return not(l=r);
  end function;

  ------------------------------------------
  -- RESET
  ------------------------------------------

  -- get cplx reset value 
  -- RE/IM data will be 0 with option 'R', otherwise data is do-not-care
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx16 is
    variable dout : cplx16 := (rst=>'1', vld|ovf=>'0', re|im=>(others=>'-'));
  begin
    assert w=16 -- VHDL-2008 compatibility check
      report "ERROR in cplx16 reset: Output resolution must be always w=16"
      severity failure;
    if m='R' then dout.re:=(others=>'0'); dout.im:=(others=>'0'); end if;
    return dout;
  end function;
  
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx18 is
    variable dout : cplx18 := (rst=>'1', vld|ovf=>'0', re|im=>(others=>'-'));
  begin
    assert w=18 -- VHDL-2008 compatibility check
      report "ERROR in cplx18 reset: Output resolution must be always w=18"
      severity failure;
    if m='R' then dout.re:=(others=>'0'); dout.im:=(others=>'0'); end if;
    return dout;
  end function;
  
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx20 is
    variable dout : cplx20 := (rst=>'1', vld|ovf=>'0', re|im=>(others=>'-'));
  begin
    assert w=20 -- VHDL-2008 compatibility check
      report "ERROR in cplx20 reset: Output resolution must be always w=20"
      severity failure;
    if m='R' then dout.re:=(others=>'0'); dout.im:=(others=>'0'); end if;
    return dout;
  end function;
  
  function cplx_reset (w:positive; m:cplx_mode:="-") return cplx22 is
    variable dout : cplx22 := (rst=>'1', vld|ovf=>'0', re|im=>(others=>'-'));
  begin
    assert w=22 -- VHDL-2008 compatibility check
      report "ERROR in cplx22 reset: Output resolution must be always w=22"
      severity failure;
    if m='R' then dout.re:=(others=>'0'); dout.im:=(others=>'0'); end if;
    return dout;
  end function;
  
  -- get cplx_vector reset value 
  -- RE/IM data will be 0 with option 'R', otherwise data is do-not-care
  -- w : RE/IM data width in bits
  -- n : number of vector elements
  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx16_vector is
    variable dout : cplx16_vector(1 to n);
  begin
    for i in dout'range loop dout(i):=cplx_reset(w=>w, m=>m); end loop;
    return dout;
  end function;

  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx18_vector is
    variable dout : cplx18_vector(1 to n);
  begin
    for i in dout'range loop dout(i):=cplx_reset(w=>w, m=>m); end loop;
    return dout;
  end function;

  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx20_vector is
    variable dout : cplx20_vector(1 to n);
  begin
    for i in dout'range loop dout(i):=cplx_reset(w=>w, m=>m); end loop;
    return dout;
  end function;

  function cplx_vector_reset (w:positive; n:positive; m:cplx_mode:="-") return cplx22_vector is
    variable dout : cplx22_vector(1 to n);
  begin
    for i in dout'range loop dout(i):=cplx_reset(w=>w, m=>m); end loop;
    return dout;
  end function;

  -- Complex data reset on demand - to be placed into the data path
  -- supported options: 'R'
  function reset_on_demand (din:cplx16; m:cplx_mode:="-") return cplx16 is
    variable dout : cplx16;
  begin
    dout := din; -- by default output = input
    if din.rst='1' then
      dout.vld:='0'; dout.ovf:='0'; -- always reset control signals
      -- reset data only when explicitly wanted
      if m='R' then dout.re:=(din.re'range=>'0'); dout.im:=(din.im'range=>'0'); end if;
    end if;
    return dout;
  end function;

  function reset_on_demand (din:cplx18; m:cplx_mode:="-") return cplx18 is
    variable dout : cplx18;
  begin
    dout := din; -- by default output = input
    if din.rst='1' then
      dout.vld:='0'; dout.ovf:='0'; -- always reset control signals
      -- reset data only when explicitly wanted
      if m='R' then dout.re:=(din.re'range=>'0'); dout.im:=(din.im'range=>'0'); end if;
    end if;
    return dout;
  end function;

  function reset_on_demand (din:cplx20; m:cplx_mode:="-") return cplx20 is
    variable dout : cplx20;
  begin
    dout := din; -- by default output = input
    if din.rst='1' then
      dout.vld:='0'; dout.ovf:='0'; -- always reset control signals
      -- reset data only when explicitly wanted
      if m='R' then dout.re:=(din.re'range=>'0'); dout.im:=(din.im'range=>'0'); end if;
    end if;
    return dout;
  end function;

  function reset_on_demand (din:cplx22; m:cplx_mode:="-") return cplx22 is
    variable dout : cplx22;
  begin
    dout := din; -- by default output = input
    if din.rst='1' then
      dout.vld:='0'; dout.ovf:='0'; -- always reset control signals
      -- reset data only when explicitly wanted
      if m='R' then dout.re:=(din.re'range=>'0'); dout.im:=(din.im'range=>'0'); end if;
    end if;
    return dout;
  end function;

  function reset_on_demand (din:cplx16_vector; m:cplx_mode:="-") return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop dout(i):=reset_on_demand(din=>din(i), m=>m); end loop; 
    return dout;
  end function;

  function reset_on_demand (din:cplx18_vector; m:cplx_mode:="-") return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop dout(i):=reset_on_demand(din=>din(i), m=>m); end loop; 
    return dout;
  end function;

  function reset_on_demand (din:cplx20_vector; m:cplx_mode:="-") return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop dout(i):=reset_on_demand(din=>din(i), m=>m); end loop; 
    return dout;
  end function;

  function reset_on_demand (din:cplx22_vector; m:cplx_mode:="-") return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop dout(i):=reset_on_demand(din=>din(i), m=>m); end loop; 
    return dout;
  end function;

  ------------------------------------------
  -- RESIZE DOWN AND SATURATE/CLIP
  ------------------------------------------

  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx16 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert w=16 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx18->cplx16 : Output resolution must be always w=16"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx16 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert w=16 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx20->cplx16 : Output resolution must be always w=16"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx16 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert w=16 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx22->cplx16 : Output resolution must be always w=16"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx18 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18;
  begin
    assert w=18 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx20->cplx18 : Output resolution must be always w=18"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx18 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18; -- default
  begin
    assert w=18 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx22->cplx18 : Output resolution must be always w=18"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx22; w:positive; m:cplx_mode:="-") return cplx20 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx20;
  begin
    assert w=20 -- VHDL-2008 compatibility check
      report "ERROR in resize cplx22->cplx20 : Output resolution must be always w=20"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if m='X' then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    RESIZE_CLIP(din=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    RESIZE_CLIP(din=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- If enabled this function reports overflows (only for valid data).
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  ------------------------------------------
  -- RESIZE DOWN VECTOR AND SATURATE/CLIP
  ------------------------------------------

  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx16_vector is
    variable res : cplx16_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx16_vector is
    variable res : cplx16_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx16_vector is
    variable res : cplx16_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx18_vector is
    variable res : cplx18_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx18_vector is
    variable res : cplx18_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx22_vector; w:positive; m:cplx_mode:="-") return cplx20_vector is
    variable res : cplx20_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din=>din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  ------------------------------------------
  -- RESIZE UP
  ------------------------------------------

  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx18 is
    constant LOUT : positive := 18;
    variable dout : cplx18;
  begin
    assert w=LOUT -- VHDL-2008 compatibility check
      report "ERROR in resize cplx16->cplx18 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx20 is
    constant LOUT : positive := 20;
    variable dout : cplx20;
  begin
    assert w=LOUT -- VHDL-2008 compatibility check
      report "ERROR in resize cplx16->cplx20 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx20 is
    constant LOUT : positive := 20;
    variable dout : cplx20;
  begin
    assert w=LOUT -- VHDL-2008 compatibility check
      report "ERROR in resize cplx18->cplx20 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx16; w:positive; m:cplx_mode:="-") return cplx22 is
    constant LOUT : positive := 22;
    variable dout : cplx22;
  begin
    assert w=LOUT -- VHDL-2008 compatibility check
      report "ERROR in resize cplx16->cplx22 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx18; w:positive; m:cplx_mode:="-") return cplx22 is
    constant LOUT : positive := 22;
    variable dout : cplx22;
  begin
    assert w=LOUT
      report "ERROR in resize cplx18->cplx22 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function resize (din:cplx20; w:positive; m:cplx_mode:="-") return cplx22 is
    constant LOUT : positive := 22;
    variable dout : cplx22;
  begin
    assert w=LOUT
      report "ERROR in resize cplx20->cplx22 : Output resolution must be always w=" & integer'image(LOUT)
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf; -- default
    dout.re  := RESIZE(din.re,LOUT);
    dout.im  := RESIZE(din.im,LOUT);
    -- Note: increasing size cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  ------------------------------------------
  -- RESIZE UP VECTOR
  ------------------------------------------

  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx18_vector is
    variable res : cplx18_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx20_vector is
    variable res : cplx20_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx20_vector is
    variable res : cplx20_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx16_vector; w:positive; m:cplx_mode:="-") return cplx22_vector is
    variable res : cplx22_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx18_vector; w:positive; m:cplx_mode:="-") return cplx22_vector is
    variable res : cplx22_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  function resize (din:cplx20_vector; w:positive; m:cplx_mode:="-") return cplx22_vector is
    variable res : cplx22_vector(din'range);
  begin
    for i in din'range loop res(i) := resize(din(i), w=>w, m=>m); end loop;
    return res;
  end function;

  ------------------------------------------
  -- Basic complex arithmetic
  ------------------------------------------

  -- complex minus CPLX16
  function "-" (din:cplx16) return cplx16 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- wrap only occurs when input is most-negative number
    SUB(l=>to_signed(0,din.re'length), r=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>false);
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>false);
    -- This function always reports overflows but only for valid data.
    dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im));
    dout := reset_on_demand(din=>dout, m=>"-"); -- never reset data
    return dout;
  end function;

  function "-" (din:cplx16_vector) return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop dout(i) := -din(i); end loop;
    return dout;
  end function;

  -- complex minus CPLX18
  function "-" (din:cplx18) return cplx18 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- wrap only occurs when input is most-negative number
    SUB(l=>to_signed(0,din.re'length), r=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>false);
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>false);
    -- This function always reports overflows but only for valid data.
    dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im));
    dout := reset_on_demand(din=>dout, m=>"-"); -- never reset data
    return dout;
  end function;

  function "-" (din:cplx18_vector) return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop dout(i) := -din(i); end loop;
    return dout;
  end function;

  -- complex minus CPLX20
  function "-" (din:cplx20) return cplx20 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx20;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- wrap only occurs when input is most-negative number
    SUB(l=>to_signed(0,din.re'length), r=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>false);
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>false);
    -- This function always reports overflows but only for valid data.
    dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im));
    dout := reset_on_demand(din=>dout, m=>"-"); -- never reset data
    return dout;
  end function;

  function "-" (din:cplx20_vector) return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop dout(i) := -din(i); end loop;
    return dout;
  end function;

  -- complex minus CPLX22
  function "-" (din:cplx22) return cplx22 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx22;
  begin
    -- by default copy input control signals
    dout.rst:=din.rst; dout.vld:=din.vld; dout.ovf:=din.ovf;
    -- wrap only occurs when input is most-negative number
    SUB(l=>to_signed(0,din.re'length), r=>din.re, dout=>dout.re, ovfl=>ovf_re, clip=>false);
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>false);
    -- This function always reports overflows but only for valid data.
    dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im));
    dout := reset_on_demand(din=>dout, m=>"-"); -- never reset data
    return dout;
  end function;

  function "-" (din:cplx22_vector) return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop dout(i) := -din(i); end loop;
    return dout;
  end function;

  -- complex conjugate CPLX16
  function conj (din:cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16 is
    variable ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert (w=0 or w=16) -- VHDL-2008 compatibility check
      report "ERROR in conj cplx16 : Output bit width must be w=0 or w=16"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.re:=din.re; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    -- overflow/underflow only possible when IM input is most-negative number
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if (m='O') then dout.ovf := dout.ovf or (dout.vld and ovf_im); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function conj (din:cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop dout(i):=conj(din=>din(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  -- complex conjugate CPLX18
  function conj (din:cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18 is
    variable ovf_im : std_logic;
    variable dout : cplx18;
  begin
    assert (w=0 or w=18) -- VHDL-2008 compatibility check
      report "ERROR in conj cplx18 : Output bit width must be w=0 or w=18"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.re:=din.re; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    -- overflow/underflow only possible when IM input is most-negative number
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if (m='O') then dout.ovf := dout.ovf or (dout.vld and ovf_im); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function conj (din:cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop dout(i):=conj(din=>din(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  -- complex conjugate CPLX20
  function conj (din:cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20 is
    variable ovf_im : std_logic;
    variable dout : cplx20;
  begin
    assert (w=0 or w=20) -- VHDL-2008 compatibility check
      report "ERROR in conj cplx20 : Output bit width must be w=0 or w=20"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.re:=din.re; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    -- overflow/underflow only possible when IM input is most-negative number
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if (m='O') then dout.ovf := dout.ovf or (dout.vld and ovf_im); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function conj (din:cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop dout(i):=conj(din=>din(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  -- complex conjugate CPLX22
  function conj (din:cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22 is
    variable ovf_im : std_logic;
    variable dout : cplx22;
  begin
    assert (w=0 or w=22) -- VHDL-2008 compatibility check
      report "ERROR in conj cplx22 : Output bit width must be w=0 or w=22"
      severity failure;
    dout.rst:=din.rst; dout.vld:=din.vld; dout.re:=din.re; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    -- overflow/underflow only possible when IM input is most-negative number
    SUB(l=>to_signed(0,din.im'length), r=>din.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if (m='O') then dout.ovf := dout.ovf or (dout.vld and ovf_im); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function conj (din:cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop dout(i):=conj(din=>din(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  -- swap real and imaginary components CPLX16
  function swap (din:cplx16) return cplx16 is
  begin
    return (rst=>din.rst, vld=>din.vld, ovf=>din.ovf, re=>din.im, im=>din.re);
  end function;

  function swap (din:cplx16_vector) return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop dout(i):=swap(din=>din(i)); end loop;
    return dout;
  end function;

  -- swap real and imaginary components CPLX18
  function swap (din:cplx18) return cplx18 is
  begin
    return (rst=>din.rst, vld=>din.vld, ovf=>din.ovf, re=>din.im, im=>din.re);
  end function;

  function swap (din:cplx18_vector) return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop dout(i):=swap(din=>din(i)); end loop;
    return dout;
  end function;

  -- swap real and imaginary components CPLX20
  function swap (din:cplx20) return cplx20 is
  begin
    return (rst=>din.rst, vld=>din.vld, ovf=>din.ovf, re=>din.im, im=>din.re);
  end function;

  function swap (din:cplx20_vector) return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop dout(i):=swap(din=>din(i)); end loop;
    return dout;
  end function;

  -- swap real and imaginary components CPLX22
  function swap (din:cplx22) return cplx22 is
  begin
    return (rst=>din.rst, vld=>din.vld, ovf=>din.ovf, re=>din.im, im=>din.re);
  end function;

  function swap (din:cplx22_vector) return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop dout(i):=swap(din=>din(i)); end loop;
    return dout;
  end function;

  ------------------------------------------
  -- ADDITION and ACCUMULATION
  ------------------------------------------

  function add (l,r: cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert (w=0 or w=16) -- VHDL-2008 compatibility check
      report "ERROR in add cplx16 : Output bit width must be w=0 or w=16"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    ADD(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    ADD(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function add (l,r: cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18;
  begin
    assert (w=0 or w=18) -- VHDL-2008 compatibility check
      report "ERROR in add cplx18 : Output bit width must be w=0 or w=18"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    ADD(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    ADD(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function add (l,r: cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx20;
  begin
    assert (w=0 or w=20) -- VHDL-2008 compatibility check
      report "ERROR in add cplx20 : Output bit width must be w=0 or w=20"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    ADD(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    ADD(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function add (l,r: cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx22;
  begin
    assert (w=0 or w=22) -- VHDL-2008 compatibility check
      report "ERROR in add cplx22 : Output bit width must be w=0 or w=22"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    ADD(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    ADD(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function add (l,r: cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector is 
    alias xl : cplx16_vector(1 to l'length) is l; -- default range
    alias xr : cplx16_vector(1 to r'length) is r; -- default range
    variable dout : cplx16_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: add() cplx16_vector, both summands must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := add(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function add (l,r: cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector is 
    alias xl : cplx18_vector(1 to l'length) is l; -- default range
    alias xr : cplx18_vector(1 to r'length) is r; -- default range
    variable dout : cplx18_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: add() cplx18_vector, both summands must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := add(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function add (l,r: cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector is 
    alias xl : cplx20_vector(1 to l'length) is l; -- default range
    alias xr : cplx20_vector(1 to r'length) is r; -- default range
    variable dout : cplx20_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: add() cplx20_vector, both summands must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := add(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function add (l,r: cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector is 
    alias xl : cplx22_vector(1 to l'length) is l; -- default range
    alias xr : cplx22_vector(1 to r'length) is r; -- default range
    variable dout : cplx22_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: add() cplx22_vector, both summands must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := add(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function "+" (l,r: cplx16) return cplx16 is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx18) return cplx18 is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx20) return cplx20 is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx22) return cplx22 is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx16_vector) return cplx16_vector is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx18_vector) return cplx18_vector is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx20_vector) return cplx20_vector is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "+" (l,r: cplx22_vector) return cplx22_vector is
  begin
    return add(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function sum (din: cplx16_vector; w:natural:=18; m:cplx_mode:="-") return cplx18 is
    constant LVEC : positive := din'length; -- vector length
    constant LOUT : positive := 18;
    constant MAX_NUM_SUMMAND : positive := 4; -- without risk of overflows
    alias d : cplx16_vector(1 to LVEC) is din; -- default range
    variable dout : cplx18;
  begin
    assert (w=LOUT) -- VHDL-2008 compatibility check
      report "ERROR in sum cplx16->cplx18 : Output bit width must be w=" & integer'image(LOUT)
      severity failure;
    assert LVEC<=MAX_NUM_SUMMAND
      report "WARNING: Only up to " & integer'image(MAX_NUM_SUMMAND) & " vector elements can be summed up without risking overflows."
      severity warning;
    dout := resize(d(1),LOUT);
    if LVEC>1 then
      for i in 2 to MINIMUM(LVEC,MAX_NUM_SUMMAND) loop
        -- overflow not possible, saturation disabled
        dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>"-");
      end loop;
      if LVEC>MAX_NUM_SUMMAND then
        for i in LVEC+1 to MAX_NUM_SUMMAND loop 
          -- overflow possible, saturation on demand
          dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>m);
        end loop;
      end if;
    end if;
    return dout;
  end function;

  function sum (din: cplx18_vector; w:natural:=20; m:cplx_mode:="-") return cplx20 is
    constant LVEC : positive := din'length; -- vector length
    constant LOUT : positive := 20;
    constant MAX_NUM_SUMMAND : positive := 4; -- without risk of overflows
    alias d : cplx18_vector(1 to LVEC) is din; -- default range
    variable dout : cplx20;
  begin
    assert (w=LOUT) -- VHDL-2008 compatibility check
      report "ERROR in sum cplx18->cplx20 : Output bit width must be w=" & integer'image(LOUT)
      severity failure;
    assert LVEC<=MAX_NUM_SUMMAND
      report "WARNING: Only up to " & integer'image(MAX_NUM_SUMMAND) & " vector elements can be summed up without risking overflows."
      severity warning;
    dout := resize(d(1),LOUT);
    if LVEC>1 then
      for i in 2 to MINIMUM(LVEC,MAX_NUM_SUMMAND) loop
        -- overflow not possible, saturation disabled
        dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>"-");
      end loop;
      if LVEC>MAX_NUM_SUMMAND then
        for i in LVEC+1 to MAX_NUM_SUMMAND loop 
          -- overflow possible, saturation on demand
          dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>m);
        end loop;
      end if;
    end if;
    return dout;
  end function;

  function sum (din: cplx20_vector; w:natural:=22; m:cplx_mode:="-") return cplx22 is
    constant LVEC : positive := din'length; -- vector length
    constant LOUT : positive := 22;
    constant MAX_NUM_SUMMAND : positive := 4; -- without risk of overflows
    alias d : cplx20_vector(1 to LVEC) is din; -- default range
    variable dout : cplx22;
  begin
    assert (w=LOUT) -- VHDL-2008 compatibility check
      report "ERROR in sum cplx20->cplx22 : Output bit width must be w=" & integer'image(LOUT)
      severity failure;
    assert LVEC<=MAX_NUM_SUMMAND
      report "WARNING: Only up to " & integer'image(MAX_NUM_SUMMAND) & " vector elements can be summed up without risking overflows."
      severity warning;
    dout := resize(d(1),LOUT);
    if LVEC>1 then
      for i in 2 to MINIMUM(LVEC,MAX_NUM_SUMMAND) loop
        -- overflow not possible, saturation disabled
        dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>"-");
      end loop;
      if LVEC>MAX_NUM_SUMMAND then
        for i in LVEC+1 to MAX_NUM_SUMMAND loop 
          -- overflow possible, saturation on demand
          dout := add(l=>dout, r=>resize(d(i),LOUT), w=>0, m=>m);
        end loop;
      end if;
    end if;
    return dout;
  end function;


  ------------------------------------------
  -- SUBTRACTION
  ------------------------------------------

  function sub (l,r: cplx16; w:natural:=16; m:cplx_mode:="-") return cplx16 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    assert (w=0 or w=16) -- VHDL-2008 compatibility check
      report "ERROR in sub cplx16 : Output bit width must be w=0 or w=16"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    SUB(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SUB(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function sub (l,r: cplx18; w:natural:=18; m:cplx_mode:="-") return cplx18 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18;
  begin
    assert (w=0 or w=18) -- VHDL-2008 compatibility check
      report "ERROR in sub cplx18 : Output bit width must be w=0 or w=18"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    SUB(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SUB(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function sub (l,r: cplx20; w:natural:=20; m:cplx_mode:="-") return cplx20 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx20;
  begin
    assert (w=0 or w=20) -- VHDL-2008 compatibility check
      report "ERROR in sub cplx20 : Output bit width must be w=0 or w=20"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    SUB(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SUB(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function sub (l,r: cplx22; w:natural:=22; m:cplx_mode:="-") return cplx22 is 
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx22;
  begin
    assert (w=0 or w=22) -- VHDL-2008 compatibility check
      report "ERROR in sub cplx22 : Output bit width must be w=0 or w=22"
      severity failure;
    dout.rst := l.rst or r.rst; --merge
    dout.vld := l.vld and r.vld; -- merge
    if m='X' then dout.ovf:='0'; else dout.ovf := l.ovf or r.ovf; end if; -- merge
    SUB(l=>l.re, r=>r.re, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SUB(l=>l.im, r=>r.im, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function sub (l,r: cplx16_vector; w:natural:=16; m:cplx_mode:="-") return cplx16_vector is 
    alias xl : cplx16_vector(1 to l'length) is l; -- default range
    alias xr : cplx16_vector(1 to r'length) is r; -- default range
    variable dout : cplx16_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: sub() cplx16_vector, minuend and subtrahend must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := sub(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function sub (l,r: cplx18_vector; w:natural:=18; m:cplx_mode:="-") return cplx18_vector is 
    alias xl : cplx18_vector(1 to l'length) is l; -- default range
    alias xr : cplx18_vector(1 to r'length) is r; -- default range
    variable dout : cplx18_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: sub() cplx18_vector, minuend and subtrahend must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := sub(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function sub (l,r: cplx20_vector; w:natural:=20; m:cplx_mode:="-") return cplx20_vector is 
    alias xl : cplx20_vector(1 to l'length) is l; -- default range
    alias xr : cplx20_vector(1 to r'length) is r; -- default range
    variable dout : cplx20_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: sub() cplx20_vector, minuend and subtrahend must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := sub(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function sub (l,r: cplx22_vector; w:natural:=22; m:cplx_mode:="-") return cplx22_vector is 
    alias xl : cplx22_vector(1 to l'length) is l; -- default range
    alias xr : cplx22_vector(1 to r'length) is r; -- default range
    variable dout : cplx22_vector(1 to l'length);
  begin
    assert (l'length=r'length)
      report "ERROR: sub() cplx22_vector, minuend and subtrahend must have same number of vector elements"
      severity failure;
    for i in dout'range loop dout(i) := sub(l=>xl(i), r=>xr(i), w=>w, m=>m); end loop;
    return dout;
  end function;

  function "-" (l,r: cplx16) return cplx16 is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx18) return cplx18 is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx20) return cplx20 is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx22) return cplx22 is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx16_vector) return cplx16_vector is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx18_vector) return cplx18_vector is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx20_vector) return cplx20_vector is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  function "-" (l,r: cplx22_vector) return cplx22_vector is
  begin
    return sub(l=>l, r=>r, m=>"O"); -- always with overflow detection
  end function;

  ------------------------------------------
 -- SHIFT LEFT AND SATURATE/CLIP
  ------------------------------------------

  -- shift left CPLX16
  function shift_left (din:cplx16 ; n:natural; m:cplx_mode:="-") return cplx16 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx16;
  begin
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    SHIFT_LEFT_CLIP(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SHIFT_LEFT_CLIP(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_left (din:cplx16_vector ; n:natural; m:cplx_mode:="-") return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_left(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift left CPLX18
  function shift_left (din:cplx18 ; n:natural; m:cplx_mode:="-") return cplx18 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx18;
  begin
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    SHIFT_LEFT_CLIP(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SHIFT_LEFT_CLIP(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_left (din:cplx18_vector ; n:natural; m:cplx_mode:="-") return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_left(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift left CPLX20
  function shift_left (din:cplx20 ; n:natural; m:cplx_mode:="-") return cplx20 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx20;
  begin
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    SHIFT_LEFT_CLIP(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SHIFT_LEFT_CLIP(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_left (din:cplx20_vector ; n:natural; m:cplx_mode:="-") return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_left(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift left CPLX22
  function shift_left (din:cplx22 ; n:natural; m:cplx_mode:="-") return cplx22 is
    variable ovf_re, ovf_im : std_logic;
    variable dout : cplx22;
  begin
    dout.rst:=din.rst; dout.vld:=din.vld; -- just forward signals
    if (m='X') then dout.ovf:='0'; else dout.ovf:=din.ovf; end if; -- ignore input overflow ?
    SHIFT_LEFT_CLIP(din=>din.re, n=>n, dout=>dout.re, ovfl=>ovf_re, clip=>(m='S'));
    SHIFT_LEFT_CLIP(din=>din.im, n=>n, dout=>dout.im, ovfl=>ovf_im, clip=>(m='S'));
    -- This function reports overflows only for valid data.
    if m='O' then dout.ovf := dout.ovf or (dout.vld and (ovf_re or ovf_im)); end if;
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_left (din:cplx22_vector ; n:natural; m:cplx_mode:="-") return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_left(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  ------------------------------------------
  -- SHIFT RIGHT and ROUND
  ------------------------------------------

  -- local auxiliary procedure to avoid massive code duplication
  procedure help_shift_right (
    rst  : in  std_logic;
    din  : in  signed;
    n    : in  natural;
    dout : out signed;
    m    : in  cplx_mode
  ) is
  begin
    if m='R' and rst='1' then
      dout := (dout'range =>'0');
    elsif m='N' then
      dout := SHIFT_RIGHT_ROUND(din, n, nearest);
    elsif m='U' then
      dout := SHIFT_RIGHT_ROUND(din, n, ceil); -- real part
    elsif m='Z' then
      dout := SHIFT_RIGHT_ROUND(din, n, truncate); -- real part
    elsif m='I' then
      dout := SHIFT_RIGHT_ROUND(din, n, infinity); -- real part
    else
      -- by default standard rounding, i.e. floor
      dout := shift_right(din, n); -- real part
    end if;
  end procedure;

  -- shift right CPLX16
  function shift_right (din:cplx16; n:natural; m:cplx_mode:="-") return cplx16 is
    variable dout : cplx16;
  begin
    help_shift_right(din.rst, din.re, n, dout.re, m);
    help_shift_right(din.rst, din.im, n, dout.im, m);
    -- Note: shift right cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_right (din:cplx16_vector ; n:natural; m:cplx_mode:="-") return cplx16_vector is
    variable dout : cplx16_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_right(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift right CPLX18
  function shift_right (din:cplx18; n:natural; m:cplx_mode:="-") return cplx18 is
    variable dout : cplx18;
  begin
    help_shift_right(din.rst, din.re, n, dout.re, m);
    help_shift_right(din.rst, din.im, n, dout.im, m);
    -- Note: shift right cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_right (din:cplx18_vector ; n:natural; m:cplx_mode:="-") return cplx18_vector is
    variable dout : cplx18_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_right(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift right CPLX20
  function shift_right (din:cplx20; n:natural; m:cplx_mode:="-") return cplx20 is
    variable dout : cplx20;
  begin
    help_shift_right(din.rst, din.re, n, dout.re, m);
    help_shift_right(din.rst, din.im, n, dout.im, m);
    -- Note: shift right cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_right (din:cplx20_vector ; n:natural; m:cplx_mode:="-") return cplx20_vector is
    variable dout : cplx20_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_right(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  -- shift right CPLX22
  function shift_right (din:cplx22; n:natural; m:cplx_mode:="-") return cplx22 is
    variable dout : cplx22;
  begin
    help_shift_right(din.rst, din.re, n, dout.re, m);
    help_shift_right(din.rst, din.im, n, dout.im, m);
    -- Note: shift right cannot cause overflow!
    dout := reset_on_demand(din=>dout, m=>m);
    return dout;
  end function;

  function shift_right (din:cplx22_vector ; n:natural; m:cplx_mode:="-") return cplx22_vector is
    variable dout : cplx22_vector(din'range);
  begin
    for i in din'range loop 
      dout(i) := shift_right(din=>din(i), n=>n, m=>m);
    end loop;
    return dout;
  end function;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX
  ------------------------------------------

  function to_cplx (
    slv : std_logic_vector(31 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx16 is
    constant BITS : integer := 16;
    variable res : cplx16;
  begin
    res.rst:=rst; res.vld:=vld; res.ovf:='0';
    res.re  := signed( slv(  BITS-1 downto    0) );
    res.im  := signed( slv(2*BITS-1 downto BITS) );
    return res;
  end function;

  function to_cplx (
    slv : std_logic_vector(35 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx18 is
    constant BITS : integer := 18;
    variable res : cplx18;
  begin
    res.rst:=rst; res.vld:=vld; res.ovf:='0';
    res.re := signed( slv(  BITS-1 downto    0) );
    res.im := signed( slv(2*BITS-1 downto BITS) );
    return res;
  end function;

  function to_cplx (
    slv : std_logic_vector(39 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx20 is
    constant BITS : integer := 20;
    variable res : cplx20;
  begin
    res.rst:=rst; res.vld:=vld; res.ovf:='0';
    res.re := signed( slv(  BITS-1 downto    0) );
    res.im := signed( slv(2*BITS-1 downto BITS) );
    return res;
  end function;

  function to_cplx (
    slv : std_logic_vector(43 downto 0);
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx22 is
    constant BITS : integer := 22;
    variable res : cplx22;
  begin
    res.rst:=rst; res.vld:=vld; res.ovf:='0';
    res.re := signed( slv(  BITS-1 downto    0) );
    res.im := signed( slv(2*BITS-1 downto BITS) );
    return res;
  end function;

  ------------------------------------------
  -- STD_LOGIC_VECTOR to CPLX VECTOR
  ------------------------------------------

  function to_cplx_vector (
    slv : std_logic_vector;
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx16_vector is
    constant BITS : integer := 16;
    variable res : cplx16_vector(0 to n-1);
  begin
    assert slv'length=(n*2*BITS)
      report "ERROR: to_cplx_vector(), input std_logic_vector length is not equal to n*" & integer'image(2*BITS)
      severity failure;
    for i in 0 to n-1 loop
      res(i) := to_cplx(slv=>slv(2*BITS*(i+1)-1 downto 2*BITS*i), vld=>vld, rst=>rst);
    end loop;
    return res;
  end function;

  function to_cplx_vector (
    slv : std_logic_vector;
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx18_vector is
    constant BITS : integer := 18;
    variable res : cplx18_vector(0 to n-1);
  begin
    assert slv'length=(n*2*BITS)
      report "ERROR: to_cplx_vector(), input std_logic_vector length is not equal to n*" & integer'image(2*BITS)
      severity failure;
    for i in 0 to n-1 loop 
      res(i) := to_cplx(slv(2*BITS*(i+1)-1 downto 2*BITS*i), vld=>vld, rst=>rst);
    end loop;
    return res;
  end function;

  function to_cplx_vector (
    slv : std_logic_vector;
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx20_vector is
    constant BITS : integer := 20;
    variable res : cplx20_vector(0 to n-1);
  begin
    assert slv'length=(n*2*BITS)
      report "ERROR: to_cplx_vector(), input std_logic_vector length is not equal to n*" & integer'image(2*BITS)
      severity failure;
    for i in 0 to n-1 loop 
      res(i) := to_cplx(slv(2*BITS*(i+1)-1 downto 2*BITS*i), vld=>vld, rst=>rst);
    end loop;
    return res;
  end function;

  function to_cplx_vector (
    slv : std_logic_vector;
    n   : positive; -- number of required vector elements
    vld : std_logic; -- valid signal
    rst : std_logic:='0' -- reset, by default '0'
  ) return cplx22_vector is
    constant BITS : integer := 22;
    variable res : cplx22_vector(0 to n-1);
  begin
    assert slv'length=(n*2*BITS)
      report "ERROR: to_cplx_vector(), input std_logic_vector length is not equal to n*" & integer'image(2*BITS)
      severity failure;
    for i in 0 to n-1 loop 
      res(i) := to_cplx(slv(2*BITS*(i+1)-1 downto 2*BITS*i), vld=>vld, rst=>rst);
    end loop;
    return res;
  end function;

  ------------------------------------------
  -- CPLX to STD_LOGIC_VECTOR
  ------------------------------------------

  function to_slv (din:cplx16; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 16;
    variable slv : std_logic_vector(2*BITS-1 downto 0);
  begin
    slv(  BITS-1 downto    0) := std_logic_vector(din.re);
    slv(2*BITS-1 downto BITS) := std_logic_vector(din.im);
    if m='R' and din.rst='1' then slv:=(others=>'0'); end if;
    return slv;
  end function;

  function to_slv (din:cplx18; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 18;
    variable slv : std_logic_vector(2*BITS-1 downto 0);
  begin
    slv(  BITS-1 downto    0) := std_logic_vector(din.re);
    slv(2*BITS-1 downto BITS) := std_logic_vector(din.im);
    if m='R' and din.rst='1' then slv:=(others=>'0'); end if;
    return slv;
  end function;

  function to_slv (din:cplx20; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 20;
    variable slv : std_logic_vector(2*BITS-1 downto 0);
  begin
    slv(  BITS-1 downto    0) := std_logic_vector(din.re);
    slv(2*BITS-1 downto BITS) := std_logic_vector(din.im);
    if m='R' and din.rst='1' then slv:=(others=>'0'); end if;
    return slv;
  end function;

  function to_slv (din:cplx22; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 22;
    variable slv : std_logic_vector(2*BITS-1 downto 0);
  begin
    slv(  BITS-1 downto    0) := std_logic_vector(din.re);
    slv(2*BITS-1 downto BITS) := std_logic_vector(din.im);
    if m='R' and din.rst='1' then slv:=(others=>'0'); end if;
    return slv;
  end function;

  ------------------------------------------
  -- CPLX VECTOR to STD_LOGIC_VECTOR
  ------------------------------------------

  function to_slv (din:cplx16_vector; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 16;
    constant N : integer := din'length;
    alias xdin : cplx16_vector(0 to N-1) is din;
    variable slv : std_logic_vector(2*BITS*N-1 downto 0);
  begin
    for i in 0 to N-1 loop
      slv(2*BITS*(i+1)-1 downto 2*BITS*i) := to_slv(din=>xdin(i), m=>m);
    end loop;
    return slv;
  end function;

  function to_slv (din:cplx18_vector; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 18;
    constant N : integer := din'length;
    alias xdin : cplx18_vector(0 to N-1) is din;
    variable slv : std_logic_vector(2*BITS*N-1 downto 0);
  begin
    for i in 0 to N-1 loop
      slv(2*BITS*(i+1)-1 downto 2*BITS*i) := to_slv(din=>xdin(i), m=>m);
    end loop;
    return slv;
  end function;

  function to_slv (din:cplx20_vector; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 20;
    constant N : integer := din'length;
    alias xdin : cplx20_vector(0 to N-1) is din;
    variable slv : std_logic_vector(2*BITS*N-1 downto 0);
  begin
    for i in 0 to N-1 loop
      slv(2*BITS*(i+1)-1 downto 2*BITS*i) := to_slv(din=>xdin(i), m=>m);
    end loop;
    return slv;
  end function;

  function to_slv (din:cplx22_vector; m:cplx_mode:="-") return std_logic_vector is
    constant BITS : integer := 22;
    constant N : integer := din'length;
    alias xdin : cplx22_vector(0 to N-1) is din;
    variable slv : std_logic_vector(2*BITS*N-1 downto 0);
  begin
    for i in 0 to N-1 loop
      slv(2*BITS*(i+1)-1 downto 2*BITS*i) := to_slv(din=>xdin(i), m=>m);
    end loop;
    return slv;
  end function;

end package body;
