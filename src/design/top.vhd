library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.utils.all;

library work;
use work.ram_controller_types.all;

entity top is
    port (
        i_reset_n : in std_logic;
        i_clk     : in std_logic;

        i_rw_n : in std_logic;
        i_as_n : in std_logic;
        i_addr : in t_sys_address;
        i_siz  : in std_logic_vector(1 downto 0);
        i_fc   : in std_logic_vector(2 downto 0);

        io_data : inout t_sys_data;

        o_addr  : out t_mem_address;
        o_ras_n : out t_bank_vector;
        o_cas_n : out t_bank_vector;

        o_oe_n : out t_byte_sel_vector;
        o_we_n : out t_byte_sel_vector;

        o_dsack_n : out std_logic);
end top;

architecture rtl of top is
    constant IO_SELECTS : integer := 2;

    signal w_mem_cs_n : std_logic;
    signal w_io_cs_n  : std_logic_vector(IO_SELECTS - 1 downto 0);

    signal w_rdy : std_logic;

    signal sync_reset_n : std_logic;
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

    reset_sync_inst : entity work.reset_sync
        port map(
            i_clk           => i_clk,
            i_async_reset_n => i_reset_n,
            o_sync_reset_n  => sync_reset_n
        );

    ram_controller_inst : entity work.ram_controller
        port map(
            i_reset_n   => sync_reset_n,
            i_clk       => i_clk,
            i_mem_cs_n  => w_mem_cs_n,
            i_conf_cs_n => w_io_cs_n(0),
            i_addr      => i_addr,
            io_data     => io_data,
            i_rw_n      => i_rw_n,
            o_addr      => o_addr,
            o_ras_n     => o_ras_n,
            o_cas_n     => o_cas_n,
            o_rdy       => w_rdy
        );

    m68k_decoder_inst : entity work.m68k_decoder
        generic map(
            IO_BASE_BLOCK      => 64,
            IO_SELECTS         => IO_SELECTS,
            MEM_BLOCK_CAPACITY => 128
        )
        port map(
            i_reset_n  => sync_reset_n,
            i_clk      => i_clk,
            i_rdy      => w_rdy,
            i_as_n     => i_as_n,
            i_addr     => i_addr,
            i_siz      => i_siz,
            i_rw_n     => i_rw_n,
            i_fc       => i_fc,
            o_we_n     => o_we_n,
            o_oe_n     => o_oe_n,
            o_io_cs_n  => w_io_cs_n,
            o_mem_cs_n => w_mem_cs_n,
            o_dsack_n  => o_dsack_n
        );
end architecture;