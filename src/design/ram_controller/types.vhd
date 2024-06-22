library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library common;
use common.utils.all;

package ram_controller_types is
    constant COLUMN_WIDTH : integer := 10;
    constant BANK_WIDTH   : integer := 1;
    constant ROW_WIDTH    : integer := 17;
    constant TOP_BANK     : integer := 2 ** BANK_WIDTH - 1;

    constant init_refresh_counter_bits : integer := 3;
    constant refresh_counter_bits      : integer := 10;
    constant small_counter_bits        : integer := 2;

    subtype t_init_refresh_counter is integer range 0 to 2 ** init_refresh_counter_bits - 1;
    subtype t_refresh_counter is integer range 0 to 2 ** refresh_counter_bits - 1;
    subtype t_small_counter is integer range 0 to 2 ** small_counter_bits - 1;

    subtype t_mem_address is std_logic_vector(MaxInt(ROW_WIDTH, COLUMN_WIDTH) - 1 downto 0);
    subtype t_row_address is std_logic_vector(ROW_WIDTH - 1 downto 0);
    subtype t_bank_address is std_logic_vector(BANK_WIDTH - 1 downto 0);
    subtype t_col_address is std_logic_vector(COLUMN_WIDTH - 1 downto 0);

    subtype t_bank is integer range 0 to TOP_BANK;
    subtype t_bank_vector is std_logic_vector(TOP_BANK downto 0);

    type controller_config_record is record
        init_refresh_threshold : t_init_refresh_counter;
        refresh_threshold      : t_refresh_counter;
        precharge_threshold    : t_small_counter;
        refresh_ras_threshold  : t_small_counter;
    end record;

    constant INIT_REFRESH_THRESHOLD_CONST : t_init_refresh_counter := 7;
    constant REFRESH_THRESHOLD_CONST      : t_refresh_counter      := 780;
    constant PRECHARGE_THRESHOLD_CONST    : t_small_counter        := 2;
    constant REFRESH_RAS_THRESHOLD_CONST  : t_small_counter        := 2;
end package;