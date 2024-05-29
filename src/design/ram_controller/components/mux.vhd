library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ram_controller_types.all;

entity mux is
    port (
        i_row_address : in row_address_t;
        i_col_address : in col_address_t;

        i_bank        : in bank_t;
        i_mux_col_sel : in bank_vector_t;

        o_addr : out mem_address_t);
end mux;
s
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
