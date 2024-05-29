library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.ram_controller_types.all;
use work.utils.all;

entity state_machine is
    port (
        i_config : in controller_config_record;

        i_clk      : in std_logic;
        i_reset_n  : in std_logic;
        i_cs_n     : in std_logic;
        i_row_addr : in row_address_t;

        o_rdy_n : out std_logic;
        o_ras_n : out std_logic;
        o_cas_n : out std_logic;

        o_mux_col_sel : out std_logic);
end entity;

architecture behavioral of state_machine is
    -- State type declaration
    type state_type is (
        RESET,
        WAIT_INIT,
        IDLE,
        ROW_ADDRESS_STROBE,
        ROW_ACTIVE,
        READ_WRITE,
        REFRESH_PRECHARGE,
        ROW_PRECHARGE,
        REFRESH_START,
        REFRESH_CAS,
        REFRESH_RAS);

    signal curr_state, next_state : state_type;

    signal config : controller_config_record;

    -- Clock Synchronized
    signal refresh_cycle_counter : refresh_counter_t := 0;     -- clk cycles to wait for next refresh
    signal refresh_ras_counter   : small_counter_t   := 0;     -- clk cycles to wait in RAS during refresh
    signal precharge_counter     : small_counter_t   := 0;     -- clk cycles to wait during precharge
    signal refresh_req           : boolean           := false; -- signals that a refresh is required
    signal open_row_addr         : row_address_t;
    signal init_refresh_counter  : init_refresh_counter_t; -- refresh cycles after wait time
    signal initialized           : boolean;
    signal row_changed           : boolean;
    signal cs_n                  : std_logic;
begin
    -- Process for state transitions and output logic
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset_n = '0' then
                curr_state <= RESET;

                initialized           <= false;
                row_changed           <= false;
                open_row_addr         <= (others => '0');
                init_refresh_counter  <= 0;
                refresh_cycle_counter <= 0;
                refresh_ras_counter   <= 0;
                precharge_counter     <= 0;
                refresh_req           <= false;

                config.init_refresh_threshold <= 1;
                config.refresh_threshold      <= 0;
                config.precharge_threshold    <= 0;
                config.refresh_ras_threshold  <= 0;

                cs_n <= '1';
            else
                curr_state <= next_state;
                cs_n       <= i_cs_n;

                if initialized then
                    if refresh_cycle_counter < config.refresh_threshold then
                        refresh_cycle_counter <= refresh_cycle_counter + 1;
                    elsif curr_state = REFRESH_START then
                        refresh_cycle_counter <= 0;
                        refresh_req           <= false;
                    else
                        refresh_req <= true;
                    end if;

                    if i_cs_n = '0' then
                        open_row_addr <= i_row_addr;
                        row_changed   <= i_row_addr /= open_row_addr;
                    end if;
                else
                    if next_state = REFRESH_PRECHARGE and curr_state /= REFRESH_PRECHARGE then
                        init_refresh_counter <= init_refresh_counter + 1;
                    end if;

                    if init_refresh_counter = config.init_refresh_threshold then
                        initialized <= true;
                    end if;

                    if i_cs_n = '0' then
                        config.init_refresh_threshold <= i_config.init_refresh_threshold;
                        config.refresh_threshold      <= i_config.refresh_threshold;
                        config.precharge_threshold    <= i_config.precharge_threshold;
                        config.refresh_ras_threshold  <= i_config.refresh_ras_threshold;
                    end if;

                    refresh_cycle_counter <= 0;
                    refresh_req           <= false;
                end if;

                if (curr_state = ROW_PRECHARGE or curr_state = REFRESH_PRECHARGE) and precharge_counter < config.precharge_threshold then
                    precharge_counter <= precharge_counter + 1;
                else
                    precharge_counter <= 0;
                end if;

                if curr_state = REFRESH_RAS and refresh_ras_counter < config.refresh_ras_threshold then
                    refresh_ras_counter <= refresh_ras_counter + 1;
                else
                    refresh_ras_counter <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Next state logic
    process (curr_state, refresh_req, cs_n, refresh_ras_counter, precharge_counter)
    begin
        case curr_state is
            when RESET =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                next_state <= WAIT_INIT;
            when WAIT_INIT =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                if cs_n = '1' then
                    next_state <= WAIT_INIT;
                else
                    next_state <= REFRESH_START;
                end if;
            when REFRESH_START =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                next_state <= REFRESH_CAS;
            when REFRESH_CAS =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '0';
                o_mux_col_sel <= '0';

                next_state <= REFRESH_RAS;

            when REFRESH_RAS =>
                o_rdy_n       <= '1';
                o_ras_n       <= '0';
                o_cas_n       <= '0';
                o_mux_col_sel <= '0';

                if refresh_ras_counter = config.refresh_ras_threshold then
                    next_state <= REFRESH_PRECHARGE;
                else
                    next_state <= REFRESH_RAS;
                end if;
            when ROW_PRECHARGE =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                if precharge_counter = config.precharge_threshold then
                    if cs_n = '1' then
                        next_state <= IDLE;
                    else
                        next_state <= ROW_ADDRESS_STROBE;
                    end if;
                else
                    next_state <= ROW_PRECHARGE;
                end if;
            when REFRESH_PRECHARGE =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                if precharge_counter = config.precharge_threshold then
                    if not initialized then
                        next_state <= REFRESH_START;
                    else
                        next_state <= IDLE;
                    end if;
                else
                    next_state <= REFRESH_PRECHARGE;
                end if;
            when IDLE =>
                o_rdy_n       <= '1';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                if refresh_req then
                    next_state <= REFRESH_START;
                elsif i_cs_n = '0' then
                    next_state <= ROW_ADDRESS_STROBE;
                else
                    next_state <= IDLE;
                end if;
            when ROW_ADDRESS_STROBE =>
                o_rdy_n       <= '1';
                o_ras_n       <= '0';
                o_cas_n       <= '1';
                o_mux_col_sel <= '0';

                next_state <= ROW_ACTIVE;
            when ROW_ACTIVE =>
                o_rdy_n       <= '1';
                o_ras_n       <= '0';
                o_cas_n       <= '1';
                o_mux_col_sel <= '1';

                if refresh_req then
                    next_state <= REFRESH_PRECHARGE;
                elsif cs_n = '0' then
                    if row_changed then
                        next_state <= ROW_PRECHARGE;
                    else
                        next_state <= READ_WRITE;
                    end if;
                else
                    next_state <= ROW_ACTIVE;
                end if;
            when READ_WRITE =>
                o_rdy_n       <= '0';
                o_ras_n       <= '0';
                o_cas_n       <= '0';
                o_mux_col_sel <= '1';

                if cs_n = '1' then
                    next_state <= ROW_ACTIVE;
                else
                    next_state <= READ_WRITE;
                end if;
        end case;
    end process;
end architecture;
