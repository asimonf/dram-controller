library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package types is
    subtype init_counter_type is unsigned(23 downto 0);
    subtype init_refresh_counter_type is unsigned(2 downto 0);
    subtype refresh_counter_type is unsigned(9 downto 0);
    subtype small_counter_type is unsigned(1 downto 0);
    subtype row_address_type is std_logic_vector(11 downto 0);

    constant INIT_COUNT_THRESHOLD_CONST   : init_counter_type         := to_unsigned(200_000_000 / 20, 24);
    constant INIT_REFRESH_THRESHOLD_CONST : init_refresh_counter_type := to_unsigned(7, 3);
    constant REFRESH_THRESHOLD_CONST      : refresh_counter_type      := to_unsigned(780, 10);
    constant PRECHARGE_THRESHOLD_CONST    : small_counter_type        := to_unsigned(3, 2);
    constant REFRESH_RAS_THRESHOLD_CONST  : small_counter_type        := to_unsigned(3, 2);

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
