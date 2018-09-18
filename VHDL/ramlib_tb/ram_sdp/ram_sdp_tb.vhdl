library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library baselib;
  use baselib.ieee_extension_types.all;
  use baselib.ieee_extension.all;
library ramlib;

entity ram_sdp_tb is
end entity;


architecture sim of ram_sdp_tb is

  constant PERIOD : time := 10 ns; -- 100MHz
  signal rst : std_logic := '1';
  signal clk : std_logic := '1';
  signal finish : std_logic := '0';

  constant DATA_WIDTH : positive := 32;
  constant ADDR_WIDTH : positive := 12;
  constant WR_USE_BYTE_ENABLE : boolean := false;
  constant WR_INPUT_REGS      : positive := 4;
  constant RD_INPUT_REGS      : positive := 1;
  constant RD_OUTPUT_REGS     : natural := 1;

  signal wr_clk_en  : std_logic := '1';
  signal wr_en      : std_logic := '0';
  signal wr_addr    : unsigned(ADDR_WIDTH-1 downto 0);
  signal wr_data    : unsigned(DATA_WIDTH-1 downto 0);
  signal wr_be      : std_logic_vector(DATA_WIDTH/8-1 downto 0) := (others=>'0');
  
  signal rd_clk_en     : std_logic := '1';
  signal rd_en         : std_logic := '0';
  signal rd_addr       : unsigned(ADDR_WIDTH-1 downto 0);
  signal bh_rd_data    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal bh_rd_data_en : std_logic;
  signal us_rd_data    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal us_rd_data_en : std_logic;

begin

  p_clk : process
  begin
    while finish='0' loop
      wait for PERIOD/2;
      clk <= not clk;
    end loop;
    -- epilog, 5 cycles
    for n in 1 to 10 loop
      wait for PERIOD/2;
      clk <= not clk;
    end loop;
    report "INFO: Clock stopped. End of simulation." severity note;
    wait; -- stop clock
  end process;

  -- release reset
  rst <= '0' after 10*PERIOD;

  p_wr : process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        wr_addr <= (others=>'0');
        wr_data <= x"03020100";
      elsif wr_en='1' then
        wr_addr <= wr_addr + 1;
        wr_data <= wr_data + x"04040404";
      end if;
    end if;
  end process;

  p_rd : process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        rd_addr <= (others=>'0');
      elsif rd_en='1' then
        rd_addr <= rd_addr + 1;
      end if;
    end if;
  end process;


  i_behave : entity ramlib.ram_sdp(behave)
  generic map(
    ADDR_WIDTH         => ADDR_WIDTH,
    WR_DATA_WIDTH      => DATA_WIDTH,
    RD_DATA_WIDTH      => DATA_WIDTH,
    WR_DEPTH           => 2**ADDR_WIDTH,
    WR_USE_BYTE_ENABLE => WR_USE_BYTE_ENABLE,
    WR_INPUT_REGS      => WR_INPUT_REGS,
    RD_INPUT_REGS      => RD_INPUT_REGS,
    RD_OUTPUT_REGS     => RD_OUTPUT_REGS
  )
  port map(
    wr_clk     => clk,
    wr_rst     => rst,
    wr_clk_en  => '1',
    wr_en      => wr_en,
    wr_addr    => std_logic_vector(wr_addr),
    wr_be      => wr_be,
    wr_data    => std_logic_vector(wr_data),
    rd_clk     => clk,
    rd_rst     => rst,
    rd_clk_en  => '1',
    rd_en      => rd_en,
    rd_addr    => std_logic_vector(rd_addr),
    rd_data    => bh_rd_data,
    rd_data_en => bh_rd_data_en
  );

  i_ultrascale : entity ramlib.ram_sdp(ultrascale)
  generic map(
    ADDR_WIDTH         => ADDR_WIDTH,
    WR_DATA_WIDTH      => DATA_WIDTH,
    RD_DATA_WIDTH      => DATA_WIDTH,
    WR_DEPTH           => 2**ADDR_WIDTH,
    WR_USE_BYTE_ENABLE => WR_USE_BYTE_ENABLE,
    WR_INPUT_REGS      => WR_INPUT_REGS,
    RD_INPUT_REGS      => RD_INPUT_REGS,
    RD_OUTPUT_REGS     => RD_OUTPUT_REGS
  )
  port map(
    wr_clk     => clk,
    wr_rst     => rst,
    wr_clk_en  => '1',
    wr_en      => wr_en,
    wr_addr    => std_logic_vector(wr_addr),
    wr_be      => wr_be,
    wr_data    => std_logic_vector(wr_data),
    rd_clk     => clk,
    rd_rst     => rst,
    rd_clk_en  => '1',
    rd_en      => rd_en,
    rd_addr    => std_logic_vector(rd_addr),
    rd_data    => us_rd_data,
    rd_data_en => us_rd_data_en
  );



  p_stimuli: process
  begin
    
    while rst='1' loop
      wait until rising_edge(clk);
    end loop;

    wait for 100 ns;
    wait until rising_edge(clk);

    wr_en <= '1';
    for n in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    
    rd_en <= '1';
    for n in 1 to 97 loop
      wait until rising_edge(clk);
    end loop;
    
    wr_en <= '0';
    rd_en <= '0';

    wait for 500 ns;
    finish <= '1';

    wait until rising_edge(clk);
    wait; -- end of process
  end process;

end architecture;

