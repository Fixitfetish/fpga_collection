-------------------------------------------------------------------------------
--! @file       signed_mult2_stratixv_partial.vhdl
--! @author     Fixitfetish
--! @date       15/Feb/2017
--! @version    0.30
--! @copyright  MIT License
--! @note       VHDL-1993
-------------------------------------------------------------------------------
-- Copyright (c) 2017 Fixitfetish
-------------------------------------------------------------------------------
library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
library fixitfetish;
 use fixitfetish.ieee_extension.all;

library stratixv;
 use stratixv.stratixv_components.all;

--! @brief This is an implementation of the entity 
--! @link signed_mult2 signed_mult2 @endlink
--! for Altera Stratix-V.
--! Two parallel and synchronous signed multiplications are performed with limited result width.
--!
--! This implementation requires a single Variable Precision DSP Block of mode 'm18x18_partial'.
--! Note that the sum of input widths x'length + y'length cannot exceed 32.
--! For details please refer to the Altera Stratix V Device Handbook.
--!
--! * Input Data      : 2x2 signed values, each max 18 bits
--! * Input Register  : optional, at least one is strongly recommended
--! * Result Register : 2x32 bits, max width of each product result is 32
--! * Rounding        : optional half-up, only possible in logic
--! * Output Data     : 2x signed values, max 32 bits each
--! * Output Register : optional, at least one strongly recommend, another after rounding, shift-right and saturation
--! * Pipeline stages : NUM_INPUT_REG + NUM_OUTPUT_REG
--!
--! Note that negation of the product results is not supported by this implementation!
--! @image html signed_mult2_stratixv_partial.svg "" width=800px
--! This implementation does not support chaining.

architecture stratixv_partial of signed_mult2 is

  -- identifier for reports of warnings and errors
  constant IMPLEMENTATION : string := "signed_mult2(stratixv_partial)";

  -- local auxiliary

  -- clock select for input/output registers
  function clock(clksel:integer range 0 to 2; nreg:integer) return string is
  begin
    if    clksel=0 and nreg>0 then return "0";
    elsif clksel=1 and nreg>0 then return "1";
    elsif clksel=2 and nreg>0 then return "2";
    else return "none";
    end if;
  end function;

  constant MAX_WIDTH_X : positive := 18;
  constant MAX_WIDTH_Y : positive := 18;

  -- accumulator width in bits
  constant MAX_PRODUCT_WIDTH : positive := 32;

  -- derived constants
  constant ROUND_ENABLE : boolean := OUTPUT_ROUND and (OUTPUT_SHIFT_RIGHT/=0);
  constant PRODUCT_WIDTH : natural := x0'length + y0'length;
  constant PRODUCT_SHIFTED_WIDTH : natural := PRODUCT_WIDTH - OUTPUT_SHIFT_RIGHT;
  constant OUTPUT_WIDTH : positive := result0'length;

  -- input register pipeline
  type r_ireg is
  record
    rst, vld : std_logic;
    x0, x1 : signed(MAX_WIDTH_X-1 downto 0);
    y0, y1 : signed(MAX_WIDTH_Y-1 downto 0);
  end record;
  type array_ireg is array(integer range <>) of r_ireg;
  signal ireg : array_ireg(NUM_INPUT_REG downto 0);

  -- output register pipeline
  type r_oreg is
  record
    dat0, dat1 : signed(OUTPUT_WIDTH-1 downto 0);
    vld : std_logic;
    ovf : std_logic_vector(result_ovf'range);
  end record;
  type array_oreg is array(integer range <>) of r_oreg;
  signal rslt : array_oreg(0 to NUM_OUTPUT_REG);

  signal prod0, prod1 : std_logic_vector(MAX_PRODUCT_WIDTH-1 downto 0);
  signal prod0_used, prod1_used : signed(PRODUCT_WIDTH-1 downto 0);
  signal prod0_used_shifted, prod1_used_shifted : signed(PRODUCT_SHIFTED_WIDTH-1 downto 0);

  -- dummy sink to avoid warnings
  procedure slv_sink(d:in std_logic_vector) is
    variable b : boolean := false;
  begin b := (d(d'right)='1') or b; end procedure;

begin

  -- check input/output length
  assert (x0'length<=MAX_WIDTH_X and x1'length<=MAX_WIDTH_X)
    report "ERROR " & IMPLEMENTATION & ": Multiplier input X width cannot exceed " & integer'image(MAX_WIDTH_X)
    severity failure;
  assert (y0'length<=MAX_WIDTH_Y and y1'length<=MAX_WIDTH_Y)
    report "ERROR " & IMPLEMENTATION & ": Multiplier input Y width cannot exceed " & integer'image(MAX_WIDTH_Y)
    severity failure;
  assert (x0'length+y0'length<=MAX_PRODUCT_WIDTH and x1'length+y1'length<=MAX_PRODUCT_WIDTH)
    report "ERROR " & IMPLEMENTATION & ": Resulting product length x'length + y'length exceeds" & integer'image(MAX_PRODUCT_WIDTH)
    severity failure;
  assert (x0'length+y0'length)=(x1'length+y1'length)
    report "ERROR " & IMPLEMENTATION & ": Both products must result in same length."
    severity failure;

  -- dummy sink for unused negation input (avoid warnings)
  slv_sink(neg);
  assert neg="00"
    report "ERROR " & IMPLEMENTATION & ": Negation of products is not supported."
    severity failure;

  -- control signal inputs
  ireg(NUM_INPUT_REG).rst <= rst;
  ireg(NUM_INPUT_REG).vld <= vld;

  -- LSB bound data inputs
  ireg(NUM_INPUT_REG).x0 <= resize(x0,MAX_WIDTH_X);
  ireg(NUM_INPUT_REG).y0 <= resize(y0,MAX_WIDTH_Y);
  ireg(NUM_INPUT_REG).x1 <= resize(x1,MAX_WIDTH_X);
  ireg(NUM_INPUT_REG).y1 <= resize(y1,MAX_WIDTH_Y);

  g_reg : if NUM_INPUT_REG>=2 generate
  begin
    g_1 : for n in 2 to NUM_INPUT_REG generate
    begin
      ireg(n-1) <= ireg(n) when rising_edge(clk);
    end generate;
  end generate;

  g_in : if NUM_INPUT_REG>=1 generate
  begin
    ireg(0).rst <= ireg(1).rst when rising_edge(clk);
    ireg(0).vld <= ireg(1).vld when rising_edge(clk);
    -- DSP cell registers are used for first input register stage
    ireg(0).x0 <= ireg(1).x0;
    ireg(0).y0 <= ireg(1).y0;
    ireg(0).x1 <= ireg(1).x1;
    ireg(0).y1 <= ireg(1).y1;
  end generate;

  dsp : stratixv_mac
  generic map (
    accumulate_clock          => "none", --irrelevant
    ax_clock                  => clock(0,NUM_INPUT_REG),
    ax_width                  => MAX_WIDTH_X,
    ay_scan_in_clock          => clock(0,NUM_INPUT_REG),
    ay_scan_in_width          => MAX_WIDTH_Y,
    ay_use_scan_in            => "false",
    az_clock                  => "none", -- unused here
    az_width                  => 1, -- unused here
    bx_clock                  => clock(0,NUM_INPUT_REG),
    bx_width                  => MAX_WIDTH_X,
    by_clock                  => clock(0,NUM_INPUT_REG),
    by_use_scan_in            => "false",
    by_width                  => MAX_WIDTH_Y,
    coef_a_0                  => 0,
    coef_a_1                  => 0,
    coef_a_2                  => 0,
    coef_a_3                  => 0,
    coef_a_4                  => 0,
    coef_a_5                  => 0,
    coef_a_6                  => 0,
    coef_a_7                  => 0,
    coef_b_0                  => 0,
    coef_b_1                  => 0,
    coef_b_2                  => 0,
    coef_b_3                  => 0,
    coef_b_4                  => 0,
    coef_b_5                  => 0,
    coef_b_6                  => 0,
    coef_b_7                  => 0,
    coef_sel_a_clock          => "none",
    coef_sel_b_clock          => "none",
    complex_clock             => "none",
    delay_scan_out_ay         => "false",
    delay_scan_out_by         => "false",
    load_const_clock          => "none", -- irrelevant
    load_const_value          => 0, -- irrelevant
    lpm_type                  => "stratixv_mac",
    mode_sub_location         => 0,
    negate_clock              => "none", -- irrelevant
    operand_source_max        => "input",
    operand_source_may        => "input",
    operand_source_mbx        => "input",
    operand_source_mby        => "input",
    operation_mode            => "m18x18_partial",
    output_clock              => clock(1,NUM_OUTPUT_REG),
    preadder_subtract_a       => "false",
    preadder_subtract_b       => "false",
    result_a_width            => MAX_PRODUCT_WIDTH,
    result_b_width            => MAX_PRODUCT_WIDTH,
    scan_out_width            => 1,
    signed_max                => "true",
    signed_may                => "true",
    signed_mbx                => "true",
    signed_mby                => "true",
    sub_clock                 => "none",
    use_chainadder            => "false"
  )
  port map (
    accumulate => '0',
    aclr(0)    => '0', -- clear input registers
    aclr(1)    => ireg(0).rst, -- clear output registers
    ax         => std_logic_vector(ireg(0).x0),
    ay         => std_logic_vector(ireg(0).y0),
    az         => open,
    bx         => std_logic_vector(ireg(0).x1),
    by         => std_logic_vector(ireg(0).y1),
    chainin    => open,
    chainout   => open,
    cin        => open,
    clk(0)     => clk, -- input clock
    clk(1)     => clk, -- output clock
    clk(2)     => clk, -- unused
    coefsela   => open,
    coefselb   => open,
    complex    => open,
    cout       => open,
    dftout     => open,
    ena(0)     => '1', -- clk(0) enable
    ena(1)     => ireg(0).vld, -- clk(1) enable
    ena(2)     => '0', -- clk(2) enable - unused
    loadconst  => '0',
    negate     => '0',
    resulta    => prod0,
    resultb    => prod1,
    scanin     => open,
    scanout    => open,
    sub        => '0'
  );

  -- cut off unused sign extension bits
  -- (This reduces the logic consumption in the following steps when rounding,
  -- saturation and/or overflow detection is enabled.)
  prod0_used <= signed(prod0(PRODUCT_WIDTH-1 downto 0));
  prod1_used <= signed(prod1(PRODUCT_WIDTH-1 downto 0));

  -- shift right and round 
  g_rnd_off : if (not ROUND_ENABLE) generate
    prod0_used_shifted <= RESIZE(SHIFT_RIGHT_ROUND(prod0_used, OUTPUT_SHIFT_RIGHT),PRODUCT_SHIFTED_WIDTH);
    prod1_used_shifted <= RESIZE(SHIFT_RIGHT_ROUND(prod1_used, OUTPUT_SHIFT_RIGHT),PRODUCT_SHIFTED_WIDTH);
  end generate;
  g_rnd_on : if (ROUND_ENABLE) generate
    prod0_used_shifted <= RESIZE(SHIFT_RIGHT_ROUND(prod0_used, OUTPUT_SHIFT_RIGHT, nearest),PRODUCT_SHIFTED_WIDTH);
    prod1_used_shifted <= RESIZE(SHIFT_RIGHT_ROUND(prod1_used, OUTPUT_SHIFT_RIGHT, nearest),PRODUCT_SHIFTED_WIDTH);
  end generate;

  p_out : process(prod0_used_shifted, prod1_used_shifted, ireg(0).vld)
    variable v_dat0, v_dat1 : signed(OUTPUT_WIDTH-1 downto 0);
    variable v_ovf : std_logic_vector(result_ovf'range);
  begin
    RESIZE_CLIP(din=>prod0_used_shifted, dout=>v_dat0, ovfl=>v_ovf(0), clip=>OUTPUT_CLIP);
    RESIZE_CLIP(din=>prod1_used_shifted, dout=>v_dat1, ovfl=>v_ovf(1), clip=>OUTPUT_CLIP);
    rslt(0).vld <= ireg(0).vld;
    rslt(0).dat0 <= v_dat0;
    rslt(0).dat1 <= v_dat1;
    if OUTPUT_OVERFLOW then rslt(0).ovf<=v_ovf; else rslt(0).ovf<=(others=>'0'); end if;
  end process;

  g_oreg1 : if NUM_OUTPUT_REG>=1 generate
  begin
    rslt(1).vld <= rslt(0).vld when rising_edge(clk); -- VLD bypass
    -- DSP cell result/accumulator register is always used as first output register stage
    rslt(1).dat0 <= rslt(0).dat0;
    rslt(1).dat1 <= rslt(0).dat1;
    rslt(1).ovf <= rslt(0).ovf;
  end generate;

  -- additional output registers always in logic
  g_oreg2 : if NUM_OUTPUT_REG>=2 generate
    g_loop : for n in 2 to NUM_OUTPUT_REG generate
      rslt(n) <= rslt(n-1) when rising_edge(clk);
    end generate;
  end generate;

  -- map result to output port
  result0 <= rslt(NUM_OUTPUT_REG).dat0;
  result1 <= rslt(NUM_OUTPUT_REG).dat1;
  result_vld(0) <= rslt(NUM_OUTPUT_REG).vld;
  result_vld(1) <= rslt(NUM_OUTPUT_REG).vld;
  result_ovf <= rslt(NUM_OUTPUT_REG).ovf;

  -- report constant number of pipeline register stages
  PIPESTAGES <= NUM_INPUT_REG + NUM_OUTPUT_REG;

end architecture;
