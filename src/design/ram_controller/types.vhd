library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.utils.all;

package ram_controller_types is
    constant COLUMN_WIDTH : integer := 10;
    constant BANK_WIDTH   : integer := 2;
    constant ROW_WIDTH    : integer := 16;

    constant TOP_BANK : integer := 2 ** BANK_WIDTH - 1;
    subtype mem_address_t is std_logic_vector(MaxInt(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0);

    subtype row_address_t is std_logic_vector(ROW_WIDTH - 1 downto 0);
    subtype bank_address_t is std_logic_vector(BANK_WIDTH - 1 downto 0);
    subtype col_address_t is std_logic_vector(COLUMN_WIDTH - 1 downto 0);

    subtype bank_t is integer range 0 to TOP_BANK;
    subtype bank_vector_t is std_logic_vector(TOP_BANK downto 0);

    constant init_refresh_counter_bits : integer := 15;
    constant refresh_counter_bits      : integer := 1023;
    constant small_counter_bits        : integer := 3;

    subtype init_refresh_counter_t is integer range 0 to 2 ** init_refresh_counter_bits - 1;
    subtype refresh_counter_t is integer range 0 to 2 ** refresh_counter_bits - 1;
    subtype small_counter_t is integer range 0 to 2 ** small_counter_bits - 1;

    constant INIT_REFRESH_THRESHOLD_CONST : init_refresh_counter_t := 7;
    constant REFRESH_THRESHOLD_CONST      : refresh_counter_t      := 780;
    constant PRECHARGE_THRESHOLD_CONST    : small_counter_t        := 2;
    constant REFRESH_RAS_THRESHOLD_CONST  : small_counter_t        := 2;

    type controller_config_record is record
        init_refresh_threshold : init_refresh_counter_t;
        refresh_threshold      : refresh_counter_t;
        precharge_threshold    : small_counter_t;
        refresh_ras_threshold  : small_counter_t;
    end record;
end package;
