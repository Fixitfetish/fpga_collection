-------------------------------------------------------------------------------
--! @file       cplx_mult.sdr.vhdl
--! @author     Fixitfetish
--! @date       30/Oct/2019
--! @version    0.61
--! @note       VHDL-2008
--! @copyright  <https://en.wikipedia.org/wiki/MIT_License> ,
--!             <https://opensource.org/licenses/MIT>
-------------------------------------------------------------------------------
-- Includes DOXYGEN support.
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library baselib;
  use baselib.ieee_extension_types.all;
  use baselib.pipereg_pkg.all;
library cplxlib;
  use cplxlib.cplx_pkg.all;
library dsplib;

--! @brief Single Data Rate implementation of the entity cplx_mult .
--! N complex multiplications are performed.
--!
--! This implementation requires the entity signed_mult_sum.
--! @image html cplx_mult.sdr.svg "" width=600px
--!
--! In general this multiplier can be used when FPGA DSP cells are clocked with
--! the standard system clock. 
--!
--! NOTE: The double rate clock 'clk2' is irrelevant and unused here.
--!
architecture sdr of cplx_mult is

  constant rst : std_logic := '0'; -- TODO  global reset
  constant clkena : std_logic := '1'; -- TODO  clock enable

  -- The number of pipeline stages is reported as constant at the output port
  -- of the DSP implementation. PIPE_DSP is not a generic and it cannot be used
  -- to constrain the length of a pipeline, hence a maximum pipeline length
  -- must be defined here. Increase the value if required.
  constant MAX_NUM_PIPE_DSP : positive := 16;

  -- bit resolution of input and output data
  constant WIDTH_X : positive := x(x'left).re'length;
  constant WIDTH_Y : positive := y(y'left).re'length;
  constant WIDTH_R : positive := result(result'left).re'length;

  -- number of elements of factor vector
  -- (must be either 1 or the same length as x)
  constant NUM_FACTOR : positive := y'length;

  -- convert to default range
  alias y_i : cplx_vector(0 to NUM_FACTOR-1)(re(WIDTH_Y-1 downto 0),im(WIDTH_Y-1 downto 0)) is y;

  signal x_re, x_im : signed_vector(0 to 2*NUM_MULT-1)(WIDTH_X-1 downto 0);
  signal y_re, y_im : signed_vector(0 to 2*NUM_MULT-1)(WIDTH_Y-1 downto 0);
  signal neg_re, neg_im : std_logic_vector(0 to 2*NUM_MULT-1) := (others=>'0');

  -- merged input signals and compensate for multiplier pipeline stages
  type t_delay is array(integer range <>) of std_logic_vector(0 to NUM_MULT-1);
  signal rst_i : t_delay(0 to MAX_NUM_PIPE_DSP) := (others=>(others=>'1'));
  signal ovf : t_delay(0 to MAX_NUM_PIPE_DSP) := (others=>(others=>'0'));

  -- auxiliary
  signal vld : std_logic_vector(0 to NUM_MULT-1) := (others=>'0');
  signal data_reset : std_logic_vector(0 to NUM_MULT-1) := (others=>'0');
  type t_aux_delay is array(integer range <>) of std_logic_vector(AUX_DEFAULT'range);
  signal aux_q : t_aux_delay(0 to MAX_NUM_PIPE_DSP) := (others=>AUX_DEFAULT);

  -- DSP output signals
  signal r_ovf_re, r_ovf_im : std_logic_vector(0 to NUM_MULT-1);
  signal rslt : cplx_vector(0 to NUM_MULT-1)(re(WIDTH_R-1 downto 0),im(WIDTH_R-1 downto 0));

  -- pipeline stages of used DSP cell
  type t_pipe is array(integer range <>) of natural;
  signal PIPE_DSP : t_pipe(0 to NUM_MULT-1);

  -- dummy sink to avoid warnings
  procedure dummy_sink(si:in std_logic) is
    variable sv : std_logic := '1';
  begin sv:=sv or si; end procedure;

begin

  -- dummy sink for unused clock
  dummy_sink(clk2);

  g_merge : for n in 0 to NUM_MULT-1 generate
    g1 : if NUM_FACTOR=1 generate
      -- merge input control signals
      rst_i(0)(n) <= (x(n).rst or y_i(0).rst);
      vld(n) <= (x(n).vld and y_i(0).vld) when rst_i(0)(n)='0' else '0';
      -- Consider overflow flags of all inputs.
      -- If the overflow flag of any input is set then also the result
      -- will have the overflow flag set.   
      ovf(0)(n) <= '0' when (MODE='X' or rst_i(0)(n)='1') else
                   (x(n).ovf or y_i(0).ovf);
    end generate;
    gn : if NUM_FACTOR=NUM_MULT generate
      -- merge input control signals
      rst_i(0)(n) <= (x(n).rst or y_i(n).rst);
      vld(n) <= (x(n).vld and y_i(n).vld) when rst_i(0)(n)='0' else '0';
      -- Consider overflow flags of all inputs.
      -- If the overflow flag of any input is set then also the result
      -- will have the overflow flag set.   
      ovf(0)(n) <= '0' when (MODE='X' or rst_i(0)(n)='1') else
                   (x(n).ovf or y_i(n).ovf);
    end generate;
  end generate;

  g_in : for n in 0 to NUM_MULT-1 generate
    -- map inputs for calculation of real component
    neg_re(2*n)   <= neg(n) when USE_NEGATION else '0'; -- +/-(+x.re*y.re)
    neg_re(2*n+1) <= not neg(n) when USE_NEGATION else '1'; -- +/-(-x.im*y.im)
    x_re(2*n)     <= x(n).re;
    x_re(2*n+1)   <= x(n).im;
    -- map inputs for calculation of imaginary component
    neg_im(2*n)   <= neg(n) when USE_NEGATION else '0'; -- +/-(+x.re*y.im)
    neg_im(2*n+1) <= neg(n) when USE_NEGATION else '0'; -- +/-(+x.im*y.re)
    x_im(2*n)     <= x(n).re;
    x_im(2*n+1)   <= x(n).im;
    g1 : if NUM_FACTOR=1 generate
      -- map inputs for calculation of real component
      y_re(2*n)     <= y_i(0).re;
      y_re(2*n+1)   <= y_i(0).im;
      -- map inputs for calculation of imaginary component
      y_im(2*n)     <= y_i(0).im;
      y_im(2*n+1)   <= y_i(0).re;
    end generate;
    gn : if NUM_FACTOR=NUM_MULT generate
      -- map inputs for calculation of real component
      y_re(2*n)     <= y_i(n).re;
      y_re(2*n+1)   <= y_i(n).im;
      -- map inputs for calculation of imaginary component
      y_im(2*n)     <= y_i(n).im;
      y_im(2*n+1)   <= y_i(n).re;
    end generate;
  end generate;

  -- reset result data output to zero
  data_reset <= rst_i(0) when MODE='R' else (others=>'0');

  -- feed auxiliary signal pipeline
  aux_q(0) <= aux;

  -- accumulator delay compensation (DSP bypassed!)
  g_delay : for n in 1 to MAX_NUM_PIPE_DSP generate
    pipereg(xout=>rst_i(n), xin=>rst_i(n-1), clk=>clk, ce=>clkena);
    pipereg(xout=>ovf(n), xin=>ovf(n-1), clk=>clk, ce=>clkena);
    pipereg(xout=>aux_q(n), xin=>aux_q(n-1), clk=>clk, ce=>clkena, rst=>rst, rstval=>AUX_DEFAULT);
  end generate;

  g_mult : for n in 0 to NUM_MULT-1 generate
    -- calculate real component
    i_re : entity dsplib.signed_mult_sum
    generic map(
      NUM_MULT           => 2, -- two multiplications per complex multiplication
      HIGH_SPEED_MODE    => HIGH_SPEED_MODE,
      USE_NEGATION       => true,
      NUM_INPUT_REG      => NUM_INPUT_REG,
      NUM_OUTPUT_REG     => 1, -- always enable DSP cell output register (= first output register)
      OUTPUT_SHIFT_RIGHT => OUTPUT_SHIFT_RIGHT,
      OUTPUT_ROUND       => (MODE='N'),
      OUTPUT_CLIP        => (MODE='S'),
      OUTPUT_OVERFLOW    => (MODE='O')
    )
    port map (
     clk        => clk,
     rst        => data_reset(n),
     vld        => vld(n),
     neg        => neg_re(2*n to 2*n+1),
     x          => x_re(2*n to 2*n+1),
     y          => y_re(2*n to 2*n+1),
     result     => rslt(n).re,
     result_vld => rslt(n).vld,
     result_ovf => r_ovf_re(n),
     PIPESTAGES => PIPE_DSP(n)
    );

    -- calculate imaginary component
    i_im : entity dsplib.signed_mult_sum
    generic map(
      NUM_MULT           => 2, -- two multiplications per complex multiplication
      HIGH_SPEED_MODE    => HIGH_SPEED_MODE,
      USE_NEGATION       => true,
      NUM_INPUT_REG      => NUM_INPUT_REG,
      NUM_OUTPUT_REG     => 1, -- always enable DSP cell output register (= first output register)
      OUTPUT_SHIFT_RIGHT => OUTPUT_SHIFT_RIGHT,
      OUTPUT_ROUND       => (MODE='N'),
      OUTPUT_CLIP        => (MODE='S'),
      OUTPUT_OVERFLOW    => (MODE='O')
    )
    port map (
     clk        => clk,
     rst        => data_reset(n),
     vld        => vld(n),
     neg        => neg_im(2*n to 2*n+1),
     x          => x_im(2*n to 2*n+1),
     y          => y_im(2*n to 2*n+1),
     result     => rslt(n).im,
     result_vld => open, -- same as real component
     result_ovf => r_ovf_im(n),
     PIPESTAGES => open  -- same as real component
    );

    -- pipeline delay is the same for all
    rslt(n).rst <= rst_i(PIPE_DSP(0))(n);
    rslt(n).ovf <= (r_ovf_re(n) or r_ovf_im(n)) when MODE='X' else
                   (r_ovf_re(n) or r_ovf_im(n) or ovf(PIPE_DSP(0))(n));
  end generate;

  -- result output pipeline
  i_out : entity cplxlib.cplx_vector_pipeline
  generic map(
    NUM_PIPELINE_STAGES => NUM_OUTPUT_REG,
    MODE                => MODE
  )
  port map(
    clk        => clk,
    rst        => open, -- TODO
    clkena     => clkena,
    din        => rslt,
    dout       => result
  );

  -- report constant number of pipeline register stages (in 'clk' domain)
  PIPESTAGES <= PIPE_DSP(0) + NUM_OUTPUT_REG;

  -- auxiliary signal output
  result_aux <= aux_q(PIPE_DSP(0)+NUM_OUTPUT_REG);

end architecture;
