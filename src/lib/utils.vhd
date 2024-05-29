library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package utils is
    constant ADDRESS_WIDTH    : integer := 28;

    subtype sys_address_t is std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
    subtype byte_sel_vector_t is std_logic_vector(3 downto 0);

    function MaxInt(a : integer; b : integer) return integer;
end package;

package body utils is
    function MaxInt(a : integer; b : integer) return integer is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function MaxInt;
end package body;
