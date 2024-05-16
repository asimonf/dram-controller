library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package types is
    subtype init_counter_type is unsigned(23 downto 0);
    subtype init_refresh_counter_type is unsigned(2 downto 0);
    subtype refresh_counter_type is unsigned(9 downto 0);
    subtype small_counter_type is unsigned(1 downto 0);
    subtype row_address_type is std_logic_vector(11 downto 0);

    type controller_config_record is record
        init_count_threshold   : init_counter_type;
        init_refresh_threshold : init_refresh_counter_type;
        refresh_threshold      : refresh_counter_type;
        precharge_threshold    : small_counter_type;
        refresh_ras_threshold  : small_counter_type;
    end record;
end package;

package body types is
end package body;
