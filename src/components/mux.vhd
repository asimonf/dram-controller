library ieee;
use ieee.std_logic_1164.all;

entity mux is
    generic (
        ADDRESS_WIDTH : integer := 28;
        COLUMN_WIDTH  : integer := 10;
        BANK_WIDTH    : integer := 0;
        ROW_WIDTH     : integer := 10);
    port (
        i_row_address : in std_logic_vector(ADDRESS_WIDTH - 1 downto ADDRESS_WIDTH - ROW_WIDTH);
        i_col_address : in std_logic_vector(COLUMN_WIDTH - 1 downto 0);

        i_bank        : in integer range 0 to (2 ** BANK_WIDTH) - 1;
        i_mux_col_sel : in std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);

        o_addr : out std_logic_vector(maximum(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0));
end mux;

architecture behavioral of mux is
begin
    -- ** Assertions **

    -- All addresses must have a column width and a row width larger than 0
    assert ROW_WIDTH > 0;
    assert COLUMN_WIDTH > 0;

    -- Don't know if this is always the case for DRAM, but it must be for this design
    assert COLUMN_WIDTH <= ROW_WIDTH;

    -- Make sure the config makes sense
    assert ADDRESS_WIDTH = ROW_WIDTH + BANK_WIDTH + COLUMN_WIDTH;

    process (i_mux_col_sel, i_bank)
        variable col_sel : std_logic;
    begin
        col_sel := i_mux_col_sel(i_bank);
        o_addr <= (others => '0');

        if col_sel = '1' then
            o_addr(COLUMN_WIDTH - 1 downto 0) <= i_col_address;
        else
            o_addr(ROW_WIDTH - 1 downto 0) <= i_row_address;
        end if;
    end process;
end architecture;
