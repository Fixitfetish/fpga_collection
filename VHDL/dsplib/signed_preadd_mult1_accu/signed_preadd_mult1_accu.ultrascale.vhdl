-------------------------------------------------------------------------------
--! @file       signed_preadd_mult1_accu.ultrascale.vhdl
--! @author     Fixitfetish
--! @date       01/Jul/2017
--! @version    0.50
--! @note       VHDL-1993
--! @copyright  <https://en.wikipedia.org/wiki/MIT_License> ,
--!             <https://opensource.org/licenses/MIT>
-------------------------------------------------------------------------------
-- Includes DOXYGEN support.
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library baselib;
  use baselib.ieee_extension.all;
library dsplib;
  use dsplib.dsp_pkg_ultrascale.all;

library unisim;
  use unisim.vcomponents.all;

--! @brief This is an implementation of the entity signed_preadd_mult1_accu
--! for Xilinx UltraScale.
--! Multiply a sum of two signed (+/-AX +/-BX) with a signed Y and accumulate results.
--!
--! This implementation requires a single DSP48E2 Slice.
--! Refer to Xilinx UltraScale Architecture DSP48E2 Slice, UG579 (v1.3) November 24, 2015
--!
--! * Input Data X    : 2 signed values, each max 26 bits
--! * Input Data Y    : 1 signed value, max 18 bits
--! * Input Register  : optional, at least one is strongly recommended
--! * Input Chain     : optional, 48 bits
--! * Accu Register   : 48 bits, first output register (strongly recommended in most cases)
--! * Rounding        : optional half-up, within DSP cell
--! * Output Data     : 1x signed value, max 48 bits
--! * Output Register : optional, after shift-right and saturation
--! * Output Chain    : optional, 48 bits
--! * Pipeline stages : NUM_INPUT_REG + NUM_OUTPUT_REG
--!
--! If NUM_OUTPUT_REG=0 then the accumulator register P is disabled. 
--! This configuration might be useful when DSP cells are chained.
--!
--! Dependent on the preadder input mode the input data might need to be negated
--! using additional logic. Note that negation of the most negative value is
--! critical because an additional MSB is required.
--! In this implementation this is not an issue because the inputs ax and bx are
--! limited to 26 bits but the preadder input can be 27 bits wide.
--!
--! | PREADD AX | PREADD BX | Input D | Input A | Preadd +/- | Operation  | Comment
--! |:---------:|:---------:|:-------:|:-------:|:----------:|:----------:|:-------
--! | ADD       | ADD       |    AX   |   BX    |   '0' (+)  |    D  +  A | ---
--! | ADD       | SUBTRACT  |    AX   |   BX    |   '1' (-)  |    D  -  A | ---
--! | ADD       | DYNAMIC   |    AX   |   BX    |   sub_bx   |    D +/- A | ---
--! | SUBTRACT  | ADD       |    BX   |   AX    |   '1' (-)  |    D  -  A | ---
--! | SUBTRACT  | SUBTRACT  |   -BX   |   AX    |   '1' (-)  |   -D  -  A | additional logic required
--! | SUBTRACT  | DYNAMIC   |   -AX   |   BX    |   sub_bx   |   -D +/- A | additional logic required
--! | DYNAMIC   | ADD       |    BX   |   AX    |   sub_ax   |    D +/- A | ---
--! | DYNAMIC   | SUBTRACT  |   -BX   |   AX    |   sub_ax   |   -D +/- A | additional logic required
--! | DYNAMIC   | DYNAMIC   | +/-AX   |   BX    |   sub_bx   | +/-D +/- A | additional logic required
--!
--! This implementation can be chained multiple times.
--! @image html signed_preadd_mult1_accu.ultrascale.svg "" width=1000px

architecture ultrascale of signed_preadd_mult1_accu is

  -- identifier for reports of warnings and errors
  constant IMPLEMENTATION : string := "signed_preadd_mult1_accu(ultrascale)";

  -- number input registers within DSP and in LOGIC
  constant NUM_IREG_DSP : natural := NUM_IREG(DSP,NUM_INPUT_REG);
  constant NUM_IREG_LOGIC : natural := NUM_IREG(LOGIC,NUM_INPUT_REG);

  -- first data input register is supported, in the first stage only
  function AREG(n:natural) return natural is
  begin
    if n=0 then return 0; else return 1; end if;
  end function;

  -- second data input register is supported, in the third stage only
  function ADREG(n:natural) return natural is
  begin
    if n<=2 then return 0; else return 1; end if;
  end function;

  -- two data input registers are supported, the first and the third stage
  function BREG(n:natural) return natural is
  begin 
    if    n<=1 then return n;
    elsif n=2  then return 1; -- second input register uses MREG
    else            return 2;
    end if;
  end function;

  constant MAX_WIDTH_A  : positive := 30;
  constant MAX_WIDTH_D  : positive := 27;
  constant LIM_WIDTH_AD : positive := 26;
  constant MAX_WIDTH_B  : positive := 18;

  -- derived constants
  constant ROUND_ENABLE : boolean := OUTPUT_ROUND and (OUTPUT_SHIFT_RIGHT/=0);
  constant PRODUCT_WIDTH : natural := MAXIMUM(ax'length,bx'length) + 1 + y'length;
  constant MAX_GUARD_BITS : natural := ACCU_WIDTH - PRODUCT_WIDTH;
  constant GUARD_BITS_EVAL : natural := accu_guard_bits(NUM_SUMMAND,MAX_GUARD_BITS,IMPLEMENTATION);
  constant ACCU_USED_WIDTH : natural := PRODUCT_WIDTH + GUARD_BITS_EVAL;
  constant ACCU_USED_SHIFTED_WIDTH : natural := ACCU_USED_WIDTH - OUTPUT_SHIFT_RIGHT;
  constant OUTPUT_WIDTH : positive := result'length;

  -- logic input register pipeline
  type r_logic_ireg is
  record
    rst, clr, vld : std_logic;
    sub_ax, sub_bx : std_logic;
    ax : signed(ax'length-1 downto 0);
    bx : signed(bx'length-1 downto 0);
    y  : signed(y'length-1 downto 0);
  end record;
  type array_logic_ireg is array(integer range <>) of r_logic_ireg;
  signal logic_ireg : array_logic_ireg(NUM_IREG_LOGIC downto 0);

  -- DSP input register pipeline
  type r_dsp_ireg is
  record
    rst, vld : std_logic;
    inmode : std_logic_vector(4 downto 0);
    opmode_w : std_logic_vector(1 downto 0);
    opmode_xy : std_logic_vector(3 downto 0);
    opmode_z : std_logic_vector(2 downto 0);
    a : signed(MAX_WIDTH_A-1 downto 0);
    d : signed(MAX_WIDTH_D-1 downto 0);
    b : signed(MAX_WIDTH_B-1 downto 0);
  end record;
  type array_dsp_ireg is array(integer range <>) of r_dsp_ireg;
  signal ireg : array_dsp_ireg(NUM_IREG_DSP downto 0);

  -- preadder subtract control - more details in description above
  function preadder_subtract(sub_ax,sub_bx:std_logic; amode,bmode:string) return std_logic is
  begin
    if (bmode="DYNAMIC") then return sub_bx;
    elsif (amode="DYNAMIC") then return sub_ax;
    elsif (amode="ADD" and bmode="ADD") then return '0';
    else return '1'; end if;
  end function;

  -- input A  control - more details in description above
  function get_a(ax,bx:signed; amode,bmode:string) return signed is
  begin
    if (amode="ADD" or bmode="DYNAMIC") then return resize(bx,MAX_WIDTH_A);
    else return resize(ax,MAX_WIDTH_A); end if;
  end function;

  -- input D  control - more details in description above
  function get_d(ax,bx:signed; sub_ax:std_logic; amode,bmode:string) return signed is
  begin
    if (amode="ADD") then return resize(ax,MAX_WIDTH_D);
    elsif (bmode="ADD") then return resize(bx,MAX_WIDTH_D);
    elsif (bmode="SUBTRACT") then return -resize(bx,MAX_WIDTH_D);
    else -- bmode="DYNAMIC"
      if (amode="DYNAMIC" and sub_ax='0') then return resize(ax,MAX_WIDTH_D);
      else return -resize(ax,MAX_WIDTH_D); end if;
    end if;
  end function;

  constant clkena : std_logic := '1'; -- clock enable
  constant reset : std_logic := '0';

  signal clr_q, clr_i : std_logic;
  signal chainin_i, chainout_i : std_logic_vector(ACCU_WIDTH-1 downto 0);
  signal accu : std_logic_vector(ACCU_WIDTH-1 downto 0);
  signal accu_vld : std_logic := '0';
  signal accu_used : signed(ACCU_USED_WIDTH-1 downto 0);

begin

  -- check input/output length
  assert (ax'length<=LIM_WIDTH_AD and bx'length<=LIM_WIDTH_AD)
    report "ERROR " & IMPLEMENTATION & ": " & 
           "Preadder input AX and BX width cannot exceed " & integer'image(LIM_WIDTH_AD)
    severity failure;
  assert (y'length<=MAX_WIDTH_B)
    report "ERROR " & IMPLEMENTATION & ": " & 
           "Multiplier input Y width cannot exceed " & integer'image(MAX_WIDTH_B)
    severity failure;

  assert GUARD_BITS_EVAL<=MAX_GUARD_BITS
    report "ERROR " & IMPLEMENTATION & ": " &
           "Maximum number of accumulator bits is " & integer'image(ACCU_WIDTH) & " ." &
           "Input bit widths allow only maximum number of guard bits = " & integer'image(MAX_GUARD_BITS)
    severity failure;

  assert OUTPUT_WIDTH<ACCU_USED_SHIFTED_WIDTH or not(OUTPUT_CLIP or OUTPUT_OVERFLOW)
    report "ERROR " & IMPLEMENTATION & ": " &
           "More guard bits required for saturation/clipping and/or overflow detection."
    severity failure;

  logic_ireg(NUM_IREG_LOGIC).rst <= rst;
  logic_ireg(NUM_IREG_LOGIC).clr <= clr;
  logic_ireg(NUM_IREG_LOGIC).vld <= vld;
  logic_ireg(NUM_IREG_LOGIC).sub_ax <= sub_ax;
  logic_ireg(NUM_IREG_LOGIC).sub_bx <= sub_bx;
  logic_ireg(NUM_IREG_LOGIC).ax <= ax;
  logic_ireg(NUM_IREG_LOGIC).bx <= bx;
  logic_ireg(NUM_IREG_LOGIC).y <= y;

  g_ireg_logic : if NUM_IREG_LOGIC>=1 generate
  begin
    g_1 : for n in 1 to NUM_IREG_LOGIC generate
    begin
      logic_ireg(n-1) <= logic_ireg(n) when rising_edge(clk);
    end generate;
  end generate;

  -- support clr='1' when vld='0'
  p_clr : process(clk)
  begin
    if rising_edge(clk) then
      if logic_ireg(0).clr='1' and logic_ireg(0).vld='0' then
        clr_q<='1';
      elsif logic_ireg(0).vld='1' then
        clr_q<='0';
      end if;
    end if;
  end process;
  clr_i <= logic_ireg(0).clr or clr_q;

  -- control signal inputs
  ireg(NUM_IREG_DSP).rst <= logic_ireg(0).rst;
  ireg(NUM_IREG_DSP).vld <= logic_ireg(0).vld;
  ireg(NUM_IREG_DSP).inmode(0) <= '0'; -- AREG controlled input
  ireg(NUM_IREG_DSP).inmode(1) <= '0'; -- do not gate A/B
  ireg(NUM_IREG_DSP).inmode(2) <= '1'; -- D into preadder
  ireg(NUM_IREG_DSP).inmode(3) <= preadder_subtract(logic_ireg(0).sub_ax,logic_ireg(0).sub_bx,PREADDER_INPUT_AX,PREADDER_INPUT_BX);
  ireg(NUM_IREG_DSP).inmode(4) <= '0'; -- BREG controlled input
  ireg(NUM_IREG_DSP).opmode_xy <= "0101"; -- constant, always multiplier result M
  ireg(NUM_IREG_DSP).opmode_z <= "001" when USE_CHAIN_INPUT else "000"; -- constant
  ireg(NUM_IREG_DSP).opmode_w <= "10" when clr_i='1' else -- add rounding constant with clear signal
                                 "00" when NUM_OUTPUT_REG=0 else -- add zero when P register disabled
                                 "01"; -- feedback P accumulator register output

  -- LSB bound data inputs
  ireg(NUM_IREG_DSP).a <= get_a(logic_ireg(0).ax, logic_ireg(0).bx, PREADDER_INPUT_AX,PREADDER_INPUT_BX);
  ireg(NUM_IREG_DSP).d <= get_d(logic_ireg(0).ax, logic_ireg(0).bx, logic_ireg(0).sub_ax, PREADDER_INPUT_AX, PREADDER_INPUT_BX);
  ireg(NUM_IREG_DSP).b <= resize(logic_ireg(0).y,MAX_WIDTH_B);

  -- DSP cell data input registers AD/B2 are used as third input register stage.
  g_dsp_ireg3 : if NUM_IREG_DSP>=3 generate
  begin
    ireg(2).rst <= ireg(3).rst when rising_edge(clk);
    ireg(2).vld <= ireg(3).vld when rising_edge(clk);
    ireg(2).inmode <= ireg(3).inmode; -- for INMODE the third register delay stage is irrelevant
    ireg(2).opmode_w <= ireg(3).opmode_w when rising_edge(clk);
    ireg(2).opmode_xy <= ireg(3).opmode_xy when rising_edge(clk);
    ireg(2).opmode_z <= ireg(3).opmode_z when rising_edge(clk);
    -- the following register are located within the DSP cell
    ireg(2).a <= ireg(3).a;
    ireg(2).b <= ireg(3).b;
    ireg(2).d <= ireg(3).d;
  end generate;

  -- DSP cell MREG register is used as second data input register stage
  g_dsp_ireg2 : if NUM_IREG_DSP>=2 generate
  begin
    ireg(1).rst <= ireg(2).rst when rising_edge(clk);
    ireg(1).vld <= ireg(2).vld when rising_edge(clk);
    ireg(1).inmode <= ireg(2).inmode; -- for INMODE the second register delay stage is irrelevant
    ireg(1).opmode_w <= ireg(2).opmode_w when rising_edge(clk);
    ireg(1).opmode_xy <= ireg(2).opmode_xy when rising_edge(clk);
    ireg(1).opmode_z <= ireg(2).opmode_z when rising_edge(clk);
    -- the following register are located within the DSP cell
    ireg(1).a <= ireg(2).a;
    ireg(1).b <= ireg(2).b;
    ireg(1).d <= ireg(2).d;
  end generate;

  -- DSP cell data input registers A1/B1/D are used as first input register stage.
  g_dsp_ireg1 : if NUM_IREG_DSP>=1 generate
  begin
    ireg(0).rst <= ireg(1).rst when rising_edge(clk);
    ireg(0).vld <= ireg(1).vld when rising_edge(clk);
    -- DSP cell registers are used for first input register stage
    ireg(0).inmode <= ireg(1).inmode;
    ireg(0).opmode_w <= ireg(1).opmode_w;
    ireg(0).opmode_xy <= ireg(1).opmode_xy;
    ireg(0).opmode_z <= ireg(1).opmode_z;
    ireg(0).a <= ireg(1).a;
    ireg(0).b <= ireg(1).b;
    ireg(0).d <= ireg(1).d;
  end generate;

  -- use only LSBs of chain input
  chainin_i <= std_logic_vector(chainin(ACCU_WIDTH-1 downto 0));

  dsp : DSP48E2
  generic map(
    -- Feature Control Attributes: Data Path Selection
    AMULTSEL                  => "AD", -- use preadder for subtract feature
    A_INPUT                   => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
    BMULTSEL                  => "B", --Selects B input to multiplier (B,AD)
    B_INPUT                   => "DIRECT", -- Selects B input source,"DIRECT"(B port)or "CASCADE"(BCIN port)
    PREADDINSEL               => "A", -- Selects input to preadder (A, B)
    RND                       => RND(ROUND_ENABLE,OUTPUT_SHIFT_RIGHT), -- Rounding Constant
    USE_MULT                  => "MULTIPLY", -- Select multiplier usage (MULTIPLY,DYNAMIC,NONE)
    USE_SIMD                  => "ONE48", -- SIMD selection(ONE48, FOUR12, TWO24)
    USE_WIDEXOR               => "FALSE", -- Use the Wide XOR function (FALSE, TRUE)
    XORSIMD                   => "XOR24_48_96", -- Mode of operation for the Wide XOR (XOR24_48_96, XOR12)
    -- Pattern Detector Attributes: Pattern Detection Configuration
    AUTORESET_PATDET          => "NO_RESET", -- NO_RESET, RESET_MATCH, RESET_NOT_MATCH
    AUTORESET_PRIORITY        => "RESET", -- Priority of AUTORESET vs.CEP (RESET, CEP).
    MASK                      => x"3FFFFFFFFFFF", -- 48-bit mask value for pattern detect (1=ignore)
    PATTERN                   => x"000000000000", -- 48-bit pattern match for pattern detect
    SEL_MASK                  => "MASK", -- MASK, C, ROUNDING_MODE1, ROUNDING_MODE2
    SEL_PATTERN               => "PATTERN", -- Select pattern value (PATTERN, C)
    USE_PATTERN_DETECT        => "NO_PATDET", -- Enable pattern detect (NO_PATDET, PATDET)
    -- Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
    IS_ALUMODE_INVERTED       => "0000",
    IS_CARRYIN_INVERTED       => '0',
    IS_CLK_INVERTED           => '0',
    IS_INMODE_INVERTED        => "00000",
    IS_OPMODE_INVERTED        => "000000000",
    IS_RSTALLCARRYIN_INVERTED => '0',
    IS_RSTALUMODE_INVERTED    => '0',
    IS_RSTA_INVERTED          => '0',
    IS_RSTB_INVERTED          => '0',
    IS_RSTCTRL_INVERTED       => '0',
    IS_RSTC_INVERTED          => '0',
    IS_RSTD_INVERTED          => '0',
    IS_RSTINMODE_INVERTED     => '0',
    IS_RSTM_INVERTED          => '0',
    IS_RSTP_INVERTED          => '0',
    -- Register Control Attributes: Pipeline Register Configuration
    ACASCREG                  => AREG(NUM_INPUT_REG),-- 0,1 or 2
    ADREG                     => ADREG(NUM_INPUT_REG),-- 0 or 1
    ALUMODEREG                => INMODEREG(NUM_INPUT_REG), -- 0 or 1
    AREG                      => AREG(NUM_INPUT_REG),-- 0,1 or 2
    BCASCREG                  => BREG(NUM_INPUT_REG),-- 0,1 or 2
    BREG                      => BREG(NUM_INPUT_REG),-- 0,1 or 2
    CARRYINREG                => 1,
    CARRYINSELREG             => 1,
    CREG                      => 1,
    DREG                      => AREG(NUM_INPUT_REG),-- 0 or 1
    INMODEREG                 => INMODEREG(NUM_INPUT_REG), -- 0 or 1
    MREG                      => MREG(NUM_INPUT_REG), -- 0 or 1
    OPMODEREG                 => INMODEREG(NUM_INPUT_REG), -- 0 or 1
    PREG                      => PREG(NUM_OUTPUT_REG) -- 0 or 1
  ) 
  port map(
    -- Cascade: 30-bit (each) output: Cascade Ports
    ACOUT              => open,
    BCOUT              => open,
    CARRYCASCOUT       => open,
    MULTSIGNOUT        => open,
    PCOUT              => chainout_i,
    -- Control: 1-bit (each) output: Control Inputs/Status Bits
    OVERFLOW           => open,
    PATTERNBDETECT     => open,
    PATTERNDETECT      => open,
    UNDERFLOW          => open,
    -- Data: 4-bit (each) output: Data Ports
    CARRYOUT           => open,
    P                  => accu,
    XOROUT             => open,
    -- Cascade: 30-bit (each) input: Cascade Ports
    ACIN               => (others=>'0'), -- unused
    BCIN               => (others=>'0'), -- unused
    CARRYCASCIN        => '0', -- unused
    MULTSIGNIN         => '0', -- unused
    PCIN               => chainin_i,
    -- Control: 4-bit (each) input: Control Inputs/Status Bits
    ALUMODE            => "0000", -- always P = Z + (W + X + Y + CIN)
    CARRYINSEL         => "000", -- unused
    CLK                => clk,
    INMODE             => ireg(0).inmode,
    OPMODE(3 downto 0) => ireg(0).opmode_xy,
    OPMODE(6 downto 4) => ireg(0).opmode_z,
    OPMODE(8 downto 7) => ireg(0).opmode_w,
    -- Data: 30-bit (each) input: Data Ports
    A                  => std_logic_vector(ireg(0).a),
    B                  => std_logic_vector(ireg(0).b),
    C                  => (others=>'0'), -- unused
    CARRYIN            => '0', -- unused
    D                  => std_logic_vector(ireg(0).d),
    -- Clock Enable: 1-bit (each) input: Clock Enable Inputs
    CEA1               => clkena,
    CEA2               => clkena,
    CEAD               => clkena,
    CEALUMODE          => clkena,
    CEB1               => clkena,
    CEB2               => clkena,
    CEC                => '0', -- unused
    CECARRYIN          => '0', -- unused
    CECTRL             => clkena, -- for opmode
    CED                => clkena,
    CEINMODE           => clkena,
    CEM                => CEM(clkena,NUM_INPUT_REG),
    CEP                => ireg(0).vld,
    -- Reset: 1-bit (each) input: Reset
    RSTA               => reset, -- TODO
    RSTALLCARRYIN      => '1', -- unused
    RSTALUMODE         => reset, -- TODO
    RSTB               => reset, -- TODO
    RSTC               => '1', -- unused
    RSTCTRL            => reset, -- TODO
    RSTD               => reset, -- TODO
    RSTINMODE          => reset, -- TODO
    RSTM               => reset, -- TODO
    RSTP               => reset  -- TODO
  );

  chainout(ACCU_WIDTH-1 downto 0) <= signed(chainout_i);
  g_chainout : for n in ACCU_WIDTH to (chainout'length-1) generate
    -- sign extension (for simulation and to avoid warnings)
    chainout(n) <= chainout_i(ACCU_WIDTH-1);
  end generate;

  -- pipelined valid signal
  g_dspreg_on : if NUM_OUTPUT_REG>=1 generate
    accu_vld <= ireg(0).vld when rising_edge(clk);
  end generate;
  g_dspreg_off : if NUM_OUTPUT_REG<=0 generate
    accu_vld <= ireg(0).vld;
  end generate;

  -- cut off unused sign extension bits
  -- (This reduces the logic consumption in the following steps when rounding,
  --  saturation and/or overflow detection is enabled.)
  accu_used <= signed(accu(ACCU_USED_WIDTH-1 downto 0));

  -- right-shift and clipping
  i_out : entity dsplib.dsp_output_logic
  generic map(
    PIPELINE_STAGES    => NUM_OUTPUT_REG-1,
    OUTPUT_SHIFT_RIGHT => OUTPUT_SHIFT_RIGHT,
    OUTPUT_ROUND       => false, -- rounding already done within DSP cell!
    OUTPUT_CLIP        => OUTPUT_CLIP,
    OUTPUT_OVERFLOW    => OUTPUT_OVERFLOW
  )
  port map (
    clk         => clk,
    rst         => rst,
    dsp_out     => accu_used,
    dsp_out_vld => accu_vld,
    result      => result,
    result_vld  => result_vld,
    result_ovf  => result_ovf
  );

  -- report constant number of pipeline register stages
  PIPESTAGES <= NUM_INPUT_REG + NUM_OUTPUT_REG;

end architecture;

