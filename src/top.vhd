library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types.all;

entity top is
    generic (
        BASE_BLOCK_WIDTH : integer := 20;
        ADDRESS_WIDTH    : integer := 28;
        COLUMN_WIDTH     : integer := 10;
        BANK_WIDTH       : integer := 0;
        ROW_WIDTH        : integer := 10);
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
        o_oe_n    : out std_logic);
end top;

architecture rtl of top is
    component state_machine is
        generic (
            ROW_WIDTH : integer := ROW_WIDTH);
        port (
            i_config   : in controller_config_record;
            i_clk      : in std_logic;
            i_reset_n  : in std_logic;
            i_cs_n     : in std_logic;
            i_we_n     : in std_logic;
            i_oe_n     : in std_logic;
            i_row_addr : in std_logic_vector(ROW_WIDTH - 1 downto 0);

            o_dsack_n     : out std_logic;
            o_ras_n       : out std_logic;
            o_cas_n       : out std_logic;
            o_we_n        : out std_logic;
            o_oe_n        : out std_logic;
            o_mux_col_sel : out std_logic);
    end component;

    component mux is
        generic (
            ADDRESS_WIDTH : integer := ADDRESS_WIDTH;
            COLUMN_WIDTH  : integer := COLUMN_WIDTH;
            BANK_WIDTH    : integer := BANK_WIDTH;
            ROW_WIDTH     : integer := ROW_WIDTH);
        port (
            i_row_address : in std_logic_vector(ADDRESS_WIDTH - 1 downto ADDRESS_WIDTH - ROW_WIDTH);
            i_col_address : in std_logic_vector(COLUMN_WIDTH - 1 downto 0);

            i_bank        : in integer range 0 to (2 ** BANK_WIDTH) - 1;
            i_mux_col_sel : in std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);

            o_addr : out std_logic_vector(maximum(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0));
    end component;

    component decoder is
        generic (
            BASE_BLOCK_WIDTH : integer := BASE_BLOCK_WIDTH;
            ADDRESS_WIDTH    : integer := ADDRESS_WIDTH;
            COLUMN_WIDTH     : integer := COLUMN_WIDTH;
            BANK_WIDTH       : integer := BANK_WIDTH;
            ROW_WIDTH        : integer := ROW_WIDTH);
        port (
            i_reset_n : in std_logic;

            i_as_n : in std_logic;
            i_addr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
            i_siz  : in std_logic_vector(1 downto 0);
            i_rw_n : in std_logic;
            i_fc   : in std_logic_vector(2 downto 0);

            o_row_addr : out std_logic_vector(ROW_WIDTH - 1 downto 0);
            o_col_addr : out std_logic_vector(COLUMN_WIDTH - 1 downto 0);

            o_bank     : out integer range 0 to (2 ** BANK_WIDTH) - 1;
            o_bank_sel : out std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);

            o_we_n : out std_logic_vector(3 downto 0);
            o_oe_n : out std_logic_vector(3 downto 0);

            o_cs_n : out std_logic);
    end component;

    signal config : controller_config_record;

    signal row_addr    : std_logic_vector(ROW_WIDTH - 1 downto 0);
    signal col_addr    : std_logic_vector(COLUMN_WIDTH - 1 downto 0);
    signal bank        : integer range 0 to (2 ** BANK_WIDTH) - 1;
    signal bank_sel    : std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);
    signal mux_col_sel : std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);
    signal oe_n        : std_logic_vector(3 downto 0);
    signal we_n        : std_logic_vector(3 downto 0);
    signal cs_n        : std_logic;
begin
    config.init_refresh_threshold <= INIT_REFRESH_THRESHOLD_CONST;
    config.refresh_threshold      <= REFRESH_THRESHOLD_CONST;
    config.precharge_threshold    <= PRECHARGE_THRESHOLD_CONST;
    config.refresh_ras_threshold  <= REFRESH_RAS_THRESHOLD_CONST;

    dec_0 : decoder
    port map(
        i_reset_n  => i_reset_n,
        i_as_n     => i_as_n,
        i_addr     => i_addr,
        i_siz      => i_siz,
        i_rw_n     => i_rw_n,
        i_fc       => i_fc,
        o_row_addr => row_addr,
        o_col_addr => col_addr,
        o_bank     => bank,
        o_bank_sel => bank_sel,
        o_oe_n     => oe_n,
        o_cs_n     => cs_n,
        o_we_n     => we_n
    );

    banks : for i in 0 to 2 ** BANK_WIDTH - 1 generate
    begin
        state_machine_inst : state_machine
        generic map(
            ROW_WIDTH => ROW_WIDTH
        )
        port map(
            i_config      => config,
            i_clk         => i_clk,
            i_reset_n     => i_reset_n,
            i_cs_n        => cs_n,
            i_we_n        => we_n(i),
            i_oe_n        => oe_n(i),
            i_row_addr    => row_addr,
            o_dsack_n     => o_dsack_n,
            o_ras_n       => o_ras_n(i),
            o_cas_n       => o_cas_n(i),
            o_we_n        => o_we_n,
            o_oe_n        => o_oe_n,
            o_mux_col_sel => mux_col_sel(i)
        );
    end generate banks;

    mux_inst : mux
    generic map(
        ADDRESS_WIDTH => ADDRESS_WIDTH,
        COLUMN_WIDTH  => COLUMN_WIDTH,
        BANK_WIDTH    => BANK_WIDTH,
        ROW_WIDTH     => ROW_WIDTH
    )
    port map(
        i_row_address => row_addr,
        i_col_address => col_addr,
        i_bank        => bank,
        i_mux_col_sel => mux_col_sel,
        o_addr        => o_addr
    );

end architecture;
