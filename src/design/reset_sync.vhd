library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity reset_sync is
    port (
        i_clk           : in std_logic;
        i_async_reset_n : in std_logic;
        o_sync_reset_n  : out std_logic);
end reset_sync;

architecture behavioral of reset_sync is
    signal r_reset_1 : std_logic;
    signal r_reset_2 : std_logic;
begin
    process (i_clk, i_async_reset_n)
    begin
        if i_async_reset_n = '0' then
            r_reset_1 <= '0';
            r_reset_2 <= '0';
        elsif rising_edge(i_clk) then
            r_reset_1 <= '1';
            r_reset_2 <= r_reset_1;
        end if;
    end process;

    o_sync_reset_n <= r_reset_2;
end Behavioral;