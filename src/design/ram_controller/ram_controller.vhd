library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.utils.all;

library work;
use work.ram_controller_types.all;

entity ram_controller is
    port (
        i_reset_n : in std_logic;
        i_clk     : in std_logic;

        i_mem_cs_n  : in std_logic;
        i_conf_cs_n : in std_logic;
        i_addr      : in t_sys_address;
        io_data     : inout t_sys_data;
        i_rw_n      : in std_logic;

        o_addr  : out t_mem_address;
        o_ras_n : out t_bank_vector;
        o_cas_n : out t_bank_vector;

        o_rdy : out std_logic);
end ram_controller;

architecture behavioral of ram_controller is
    signal config : controller_config_record;

    signal row_addr    : t_row_address;
    signal col_addr    : t_col_address;
    signal bank        : t_bank;
    signal mux_col_sel : t_bank_vector;
    signal cfg_rdy     : std_logic;
    signal rdy         : t_bank_vector;

    signal mem_cs_n : std_logic;
    signal cfg_cs_n : std_logic;
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

    config_regs_inst : entity work.config_regs
        port map(
            i_clk     => i_clk,
            i_reset_n => i_reset_n,
            i_cs_n    => cfg_cs_n,
            i_rw_n    => i_rw_n,
            io_data   => io_data,
            o_config  => config,
            o_rdy     => cfg_rdy
        );

    dec_inst : entity work.decoder
        port map
        (
            i_addr     => i_addr,
            o_row_addr => row_addr,
            o_col_addr => col_addr,
            o_bank     => bank
        );

    banks_inst : for i in 0 to TOP_BANK generate
    begin
        state_machine_inst : entity work.state_machine
            port map(
                i_config      => config,
                i_clk         => i_clk,
                i_reset_n     => i_reset_n,
                i_cs_n        => mem_cs_n,
                i_row_addr    => row_addr,
                o_rdy         => rdy(i),
                o_ras_n       => o_ras_n(i),
                o_cas_n       => o_cas_n(i),
                o_mux_col_sel => mux_col_sel(i)
            );
    end generate banks_inst;

    mux_inst : entity work.mux
        port map(
            i_row_address => row_addr,
            i_col_address => col_addr,
            i_bank        => bank,
            i_mux_col_sel => mux_col_sel,
            o_addr        => o_addr
        );

    mem_cs_n <= i_mem_cs_n;
    cfg_cs_n <= i_conf_cs_n or not i_mem_cs_n;

    o_rdy <=
        cfg_rdy when cfg_cs_n = '0' else
        rdy(bank) when mem_cs_n = '0' else
        '0';
end architecture;