library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package types is
    subtype init_refresh_counter_type is integer range 0 to 15;
    subtype refresh_counter_type is integer range 0 to 1023;
    subtype small_counter_type is integer range 0 to 7;

    constant INIT_REFRESH_THRESHOLD_CONST : init_refresh_counter_type := 7;
    constant REFRESH_THRESHOLD_CONST      : refresh_counter_type      := 780;
    constant PRECHARGE_THRESHOLD_CONST    : small_counter_type        := 2;
    constant REFRESH_RAS_THRESHOLD_CONST  : small_counter_type        := 2;

    type controller_config_record is record
        init_refresh_threshold : init_refresh_counter_type;
        refresh_threshold      : refresh_counter_type;
        precharge_threshold    : small_counter_type;
        refresh_ras_threshold  : small_counter_type;
    end record;
end package;

package body types is
end package body;
