library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.types.all;

package constants is
    constant INIT_COUNT_THRESHOLD_CONST   : init_counter_type         := to_unsigned(200_000_000 / 20, 24);
    constant INIT_REFRESH_THRESHOLD_CONST : init_refresh_counter_type := to_unsigned(7, 3);
    constant REFRESH_THRESHOLD_CONST      : refresh_counter_type      := to_unsigned(780, 10);
    constant PRECHARGE_THRESHOLD_CONST    : small_counter_type        := to_unsigned(3, 2);
    constant REFRESH_RAS_THRESHOLD_CONST  : small_counter_type        := to_unsigned(3, 2);
end package;

package body constants is
end package body;
