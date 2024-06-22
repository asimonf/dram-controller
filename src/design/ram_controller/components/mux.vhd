library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ram_controller_types.all;

entity mux is
    port (
        i_row_address : in t_row_address;
        i_col_address : in t_col_address;

        i_bank        : in t_bank;
        i_mux_col_sel : in t_bank_vector;

        o_addr : out t_mem_address);
end mux;

architecture behavioral of mux is
begin
    process (i_mux_col_sel, i_bank, i_col_address, i_row_address)
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