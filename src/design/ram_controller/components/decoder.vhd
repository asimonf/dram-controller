library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library common;
use common.utils.all;

library work;
use work.ram_controller_types.all;
-- This supports bank interleaving. If the bank width is larger than 0. For practical limitations, maybe limit yourself to
-- only a few banks like 2 (bank width = 1).
-- 
-- The address word can be described as the following:
-- 
--              (                   (Address Word)                  )
--              |<--                ADDRESS_WIDTH                -->|
--              |                                                   |
--              |<- ROW_WIDTH ->/<- BANK_WIDTH ->/<- COLUMN_WIDTH ->|
--              /                                                   \
--      ADDRESS_WIDTH - 1                                            0
--
-- - The row address bits are the first ROW_WIDTH bits of the address word
-- - The selected bank bits (if defined) are going to be the the next BANK_WIDTH bits of the word after the row address
-- - The column address are going to be the next bits after the bank until the end.

entity decoder is
    port (
        i_addr : in t_sys_address;

        o_row_addr : out t_row_address;
        o_col_addr : out t_col_address;

        o_bank : out t_bank);
end decoder;

architecture behavioral of decoder is
begin
    -- Decode column and row addresses
    o_row_addr <= i_addr(ADDRESS_WIDTH - 1 downto ADDRESS_WIDTH - ROW_WIDTH);
    o_col_addr <= i_addr(COLUMN_WIDTH - 1 downto 0);

    -- ** Processes **

    -- If multiple banks are permitted, decode the bank
    multi_bank : if BANK_WIDTH > 0 generate
    begin
        process (i_addr)
            variable bank_addr : std_logic_vector(BANK_WIDTH - 1 downto 0);
            variable bank_bit  : integer range 0 to (2 ** BANK_WIDTH) - 1;
        begin
            bank_addr := i_addr(COLUMN_WIDTH + BANK_WIDTH - 1 downto COLUMN_WIDTH);
            bank_bit  := to_integer(unsigned(bank_addr));

            o_bank <= bank_bit;
        end process;
    end generate multi_bank;

    -- Otherwise just select the single bank available
    single_bank : if BANK_WIDTH = 0 generate
    begin
        o_bank <= 0;
    end generate single_bank;
end architecture;