library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;
use work.constants.all;

entity tb_state_machine is
end entity;

architecture tb of tb_state_machine is
    component RamController
        port (
            i_config      : in controller_config_record;
            i_clk         : in std_logic;
            i_reset_n     : in std_logic;
            i_cs_n        : in std_logic;
            i_we_n        : in std_logic;
            i_row_addr    : in row_address_type;
            o_dsack       : out std_logic;
            o_ras_n       : out std_logic;
            o_cas_n       : out std_logic;
            o_we_n        : out std_logic;
            o_mux_col_sel : out std_logic);
    end component;

    signal i_config      : controller_config_record;
    signal i_clk         : std_logic;
    signal i_reset_n     : std_logic;
    signal i_cs_n        : std_logic;
    signal i_we_n        : std_logic;
    signal i_row_addr    : row_address_type;
    signal o_dsack       : std_logic;
    signal o_ras_n       : std_logic;
    signal o_cas_n       : std_logic;
    signal o_we_n        : std_logic;
    signal o_mux_col_sel : std_logic;

    constant TbPeriod : time      := 20 ns; -- EDIT Put right period here
    signal TbClock    : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

    signal internal_initialized : boolean;

begin

    dut : RamController
    port map(
        i_config      => i_config,
        i_clk         => i_clk,
        i_reset_n     => i_reset_n,
        i_cs_n        => i_cs_n,
        i_we_n        => i_we_n,
        i_row_addr    => i_row_addr,
        o_dsack       => o_dsack,
        o_ras_n       => o_ras_n,
        o_cas_n       => o_cas_n,
        o_we_n        => o_we_n,
        o_mux_col_sel => o_mux_col_sel);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod / 2 when TbSimEnded /= '1' else
        '0';

    i_clk <= TbClock;

    i_config.init_count_threshold   <= to_unsigned(200, 24);
    i_config.init_refresh_threshold <= INIT_REFRESH_THRESHOLD_CONST;
    i_config.refresh_threshold      <= REFRESH_THRESHOLD_CONST;
    i_config.precharge_threshold    <= PRECHARGE_THRESHOLD_CONST;
    i_config.refresh_ras_threshold  <= REFRESH_RAS_THRESHOLD_CONST;

    internal_initialized <= << signal .tb_RamController.dut.initialized : boolean >> ;

    stimuli : process
    begin
        i_cs_n     <= '1';
        i_we_n     <= '1';
        i_row_addr <= (others => '0');

        -- Reset generation
        i_reset_n <= '0';
        wait for 100 ns;
        i_reset_n <= '1';
        wait for 100 ns;

        -- Wait for initialization
        wait until internal_initialized;

        -- Read Cycle #1
        i_cs_n     <= '0';
        i_we_n     <= '1';
        i_row_addr <= (others => '0');
        wait until o_dsack = '1';
        wait for 40 ns;
        i_cs_n <= '1';
        wait until o_dsack = '0';
        wait for 40 ns;

        -- Read Cycle #2
        i_cs_n     <= '0';
        i_we_n     <= '1';
        i_row_addr <= (others => '0');
        wait until o_dsack = '1';
        wait for 40 ns;
        i_cs_n <= '1';
        wait until o_dsack = '0';

        -- Read Cycle #3
        i_cs_n     <= '0';
        i_we_n     <= '1';
        i_row_addr <= (others => '1');
        wait until o_dsack = '1';
        wait for 40 ns;
        i_cs_n <= '1';
        wait until o_dsack = '0';

        wait for 200 ns;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end architecture;
