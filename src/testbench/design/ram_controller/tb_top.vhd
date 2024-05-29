library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity tb_top is
    generic (
        BASE_BLOCK_WIDTH : integer := 20;
        ADDRESS_WIDTH    : integer := 28;
        COLUMN_WIDTH     : integer := 10;
        BANK_WIDTH       : integer := 0;
        ROW_WIDTH        : integer := 18);
end entity;

architecture tb of tb_top is
    component top is
        generic (
            BASE_BLOCK_WIDTH : integer := BASE_BLOCK_WIDTH;
            ADDRESS_WIDTH    : integer := ADDRESS_WIDTH;
            COLUMN_WIDTH     : integer := COLUMN_WIDTH;
            BANK_WIDTH       : integer := BANK_WIDTH;
            ROW_WIDTH        : integer := ROW_WIDTH);
        port (
            i_reset_n : in std_logic;
            i_clk     : in std_logic;

            i_as_n : in std_logic;
            i_addr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
            i_siz  : in std_logic_vector(1 downto 0);
            i_rw_n : in std_logic;
            i_fc   : in std_logic_vector(2 downto 0);

            o_addr  : out std_logic_vector(maximum(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0);
            o_ras_n : out std_logic_vector(2 ** BANK_WIDTH - 1 downto 0);
            o_cas_n : out std_logic_vector(2 ** BANK_WIDTH - 1 downto 0);

            o_dsack_n : out std_logic;
            o_we_n    : out std_logic;
            o_oe_n    : out std_logic
        );
    end component;

    constant TbPeriod : time      := 20 ns; -- EDIT Put right period here
    signal TbClock    : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

    signal reset_n : std_logic;
    signal clk     : std_logic;

    signal as_n     : std_logic;
    signal cpu_addr : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
    signal siz      : std_logic_vector(1 downto 0);
    signal rw_n     : std_logic;
    signal fc       : std_logic_vector(2 downto 0);

    signal mem_addr : std_logic_vector(maximum(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0);
    signal ras_n    : std_logic_vector(2 ** BANK_WIDTH - 1 downto 0);
    signal cas_n    : std_logic_vector(2 ** BANK_WIDTH - 1 downto 0);

    signal dsack_n : std_logic;
    signal we_n    : std_logic;
    signal oe_n    : std_logic;
begin
    dut : top
    generic map(
        ADDRESS_WIDTH => ADDRESS_WIDTH,
        COLUMN_WIDTH  => COLUMN_WIDTH,
        BANK_WIDTH    => BANK_WIDTH,
        ROW_WIDTH     => ROW_WIDTH
    )
    port map(
        i_reset_n => reset_n,
        i_clk     => clk,
        i_as_n    => as_n,
        i_addr    => cpu_addr,
        i_siz     => siz,
        i_rw_n    => rw_n,
        i_fc      => fc,
        o_addr    => mem_addr,
        o_ras_n   => ras_n,
        o_cas_n   => cas_n,
        o_dsack_n => dsack_n,
        o_we_n    => we_n,
        o_oe_n    => oe_n
    );

    -- Clock generation
    TbClock <= not TbClock after TbPeriod / 2 when TbSimEnded /= '1' else
        '0';

    clk <= TbClock;

    stimuli : process
    begin
        -- Reset generation
        reset_n <= '0';
        wait for 100 ns;
        reset_n <= '1';
        wait for 100 ns;

        cpu_addr <= x"8000000";
        fc       <= "000";
        siz      <= "00";
        rw_n     <= '1';
        wait for 20 ns;
        as_n <= '0';
        wait until dsack_n = '0';
        wait for 40 ns;
        as_n <= '1';

        wait for 200 ns;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;
end architecture;
