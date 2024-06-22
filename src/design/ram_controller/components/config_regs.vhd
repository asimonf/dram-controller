library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.ram_controller_types.all;

entity config_regs is
    port (
        i_clk     : in std_logic;
        i_reset_n : in std_logic;
        i_cs_n    : in std_logic;
        i_rw_n    : in std_logic;

        io_data : inout std_logic_vector(31 downto 0);

        o_config : out controller_config_record;
        o_rdy    : out std_logic
    );
end entity config_regs;

architecture behavioral of config_regs is
    constant init_refresh_threshold_base : integer := 0;
    constant refresh_threshold_base      : integer := init_refresh_threshold_base + init_refresh_counter_bits;
    constant precharge_threshold_base    : integer := refresh_threshold_base + refresh_counter_bits;
    constant refresh_ras_threshold_base  : integer := precharge_threshold_base + small_counter_bits;

    signal config_r : controller_config_record;
    signal oe_r     : boolean;
    signal rdy      : boolean;

    signal data_r : std_logic_vector(31 downto 0);
begin
    o_config <= config_r;

    process (i_reset_n, i_clk)
    begin
        if i_reset_n = '0' then
            oe_r <= false;
            rdy  <= false;

            data_r <= (others => '0');
        elsif rising_edge(i_clk) then
            if i_cs_n = '0' then
                oe_r <= i_rw_n = '1';
                rdy  <= true;

                if i_rw_n = '0' then
                    data_r <= io_data;
                end if;
            else
                oe_r <= false;
                rdy  <= false;
            end if;
        end if;
    end process;

    config_r.init_refresh_threshold <= to_integer(unsigned(data_r(init_refresh_counter_bits - init_refresh_threshold_base - 1 downto init_refresh_threshold_base)));
    config_r.refresh_threshold      <= to_integer(unsigned(data_r(refresh_counter_bits + refresh_threshold_base - 1 downto refresh_threshold_base)));
    config_r.precharge_threshold    <= to_integer(unsigned(data_r(small_counter_bits + precharge_threshold_base - 1 downto precharge_threshold_base)));
    config_r.refresh_ras_threshold  <= to_integer(unsigned(data_r(small_counter_bits + refresh_ras_threshold_base - 1 downto refresh_ras_threshold_base)));

    io_data <= data_r when oe_r else
        (others => 'Z');

    o_rdy <= '1' when rdy else
        '0';
end architecture;