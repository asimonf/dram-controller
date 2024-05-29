library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;
use work.ram_controller_types.all;

entity ram_controller is
    port (
        i_reset_n : in std_logic;
        i_clk     : in std_logic;

        i_cs_n : in std_logic;
        i_addr : in sys_address_t;

        o_addr  : out mem_address_t;
        o_ras_n : out bank_vector_t;
        o_cas_n : out bank_vector_t;

        o_rdy_n : out std_logic);
end ram_controller;

architecture rtl of ram_controller is
    component state_machine is
        port (
            i_config   : in controller_config_record;
            i_clk      : in std_logic;
            i_reset_n  : in std_logic;
            i_cs_n     : in std_logic;
            i_row_addr : in row_address_t;

            o_rdy_n       : out std_logic;
            o_ras_n       : out std_logic;
            o_cas_n       : out std_logic;
            o_mux_col_sel : out std_logic);
    end component;

    component mux is
        port (
            i_row_address : in row_address_t;
            i_col_address : in col_address_t;

            i_bank        : in bank_t;
            i_mux_col_sel : in bank_vector_t;

            o_addr : out mem_address_t);
    end component;

    component decoder is
        port (
            i_addr : in sys_address_t;

            o_row_addr : out row_address_t;
            o_col_addr : out col_address_t;

            o_bank : out bank_t);
    end component;

    signal config : controller_config_record;

    signal row_addr    : row_address_t;
    signal col_addr    : col_address_t;
    signal bank        : bank_t;
    signal mux_col_sel : bank_vector_t;
    signal rdy_n       : bank_vector_t;
begin
    -- BEGIN Assertions

    -- All addresses must have a column width and a row width larger than 0
    assert ROW_WIDTH > 0;
    assert COLUMN_WIDTH > 0;

    -- Bank can be disabled by specifying it to be 0, but it must be positive otherwise
    assert BANK_WIDTH >= 0;

    -- Make sure the config makes sense
    assert ADDRESS_WIDTH = ROW_WIDTH + BANK_WIDTH + COLUMN_WIDTH;

    -- END Assertions

    config.init_refresh_threshold <= INIT_REFRESH_THRESHOLD_CONST;
    config.refresh_threshold      <= REFRESH_THRESHOLD_CONST;
    config.precharge_threshold    <= PRECHARGE_THRESHOLD_CONST;
    config.refresh_ras_threshold  <= REFRESH_RAS_THRESHOLD_CONST;

    dec_0 : decoder
    port map(
        i_addr     => i_addr,
        o_row_addr => row_addr,
        o_col_addr => col_addr,
        o_bank     => bank
    );

    banks : for i in 0 to TOP_BANK generate
    begin
        state_machine_inst : state_machine
        port map(
            i_config      => config,
            i_clk         => i_clk,
            i_reset_n     => i_reset_n,
            i_cs_n        => i_cs_n,
            i_row_addr    => row_addr,
            o_rdy_n       => rdy_n(i),
            o_ras_n       => o_ras_n(i),
            o_cas_n       => o_cas_n(i),
            o_mux_col_sel => mux_col_sel(i)
        );
    end generate banks;

    mux_inst : mux
    port map(
        i_row_address => row_addr,
        i_col_address => col_addr,
        i_bank        => bank,
        i_mux_col_sel => mux_col_sel,
        o_addr        => o_addr
    );

    o_rdy_n <= rdy_n(bank);
end architecture;
