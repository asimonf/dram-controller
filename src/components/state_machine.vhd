library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.types.all;

entity state_machine is
    generic (
        ROW_WIDTH : integer := 12
    );
    port (
        i_config : in controller_config_record;

        i_clk      : in std_logic;
        i_reset_n  : in std_logic;
        i_cs_n     : in std_logic;
        i_we_n     : in std_logic;
        i_oe_n     : in std_logic;
        i_row_addr : in std_logic_vector(ROW_WIDTH - 1 downto 0);

        o_dsack : out std_logic;
        o_ras_n : out std_logic;
        o_cas_n : out std_logic;
        o_we_n  : out std_logic;
        o_oe_n  : out std_logic;

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
        PRECHARGE,
        REFRESH_START,
        REFRESH_CAS,
        REFRESH_RAS);

    signal curr_state, next_state : state_type;

    -- Clock Synchronized
    signal refresh_cycle_counter : refresh_counter_type := (others => '0'); -- clk cycles to wait for next refresh
    signal refresh_ras_counter   : small_counter_type   := (others => '0'); -- clk cycles to wait in RAS during refresh
    signal precharge_counter     : small_counter_type   := (others => '0'); -- clk cycles to wait during precharge
    signal refresh_req           : boolean              := false;           -- signals that a refresh is required

    -- Async
    signal initialized          : boolean                   := false;
    signal open_row_addr        : row_address_type          := (others => '0');
    signal ras_counter_req      : boolean                   := false;
    signal refresh_taken        : boolean                   := false;
    signal precharge_started    : boolean                   := false;
    signal init_refresh_counter : init_refresh_counter_type := (others => '0'); -- refresh cycles after wait time
begin

    -- Process for state transitions and output logic
    process (i_clk, i_reset_n)
    begin
        if i_reset_n = '0' then
            curr_state <= RESET;

            refresh_cycle_counter <= (others => '0');
            refresh_ras_counter   <= (others => '0');
            precharge_counter     <= (others => '0');
            refresh_req           <= false;
        elsif rising_edge(i_clk) then
            curr_state <= next_state;

            if initialized then
                if refresh_cycle_counter < i_config.refresh_threshold then
                    refresh_cycle_counter <= refresh_cycle_counter + 1;

                    if refresh_taken then
                        refresh_req <= false;
                    end if;
                else
                    refresh_cycle_counter <= (others => '0');
                    refresh_req           <= true;
                end if;
            end if;

            if precharge_started and precharge_counter < i_config.precharge_threshold then
                precharge_counter <= precharge_counter + 1;
            elsif not precharge_started then
                precharge_counter <= (others => '0');
            end if;

            if ras_counter_req and refresh_ras_counter < i_config.refresh_ras_threshold then
                refresh_ras_counter <= refresh_ras_counter + 1;
            elsif not ras_counter_req then
                refresh_ras_counter <= (others => '0');
            end if;
        end if;
    end process;

    -- Next state logic
    process (curr_state, refresh_req, i_cs_n, refresh_ras_counter, precharge_counter)
    begin
        case curr_state is
            when RESET                      =>
                open_row_addr        <= (others => '0');
                init_refresh_counter <= (others => '0');

                initialized       <= false;
                ras_counter_req   <= false;
                refresh_taken     <= false;
                precharge_started <= false;

                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                next_state <= WAIT_INIT;
            when WAIT_INIT =>
                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                if i_cs_n = '1' then
                    next_state <= WAIT_INIT;
                else
                    next_state <= REFRESH_START;
                end if;
            when REFRESH_START =>
                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                refresh_taken <= true;
                next_state    <= REFRESH_CAS;
            when REFRESH_CAS =>
                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '0';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                next_state      <= REFRESH_RAS;
                ras_counter_req <= true;
            when REFRESH_RAS =>
                o_dsack       <= '0';
                o_ras_n       <= '0';
                o_cas_n       <= '0';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                if refresh_ras_counter = i_config.refresh_ras_threshold then
                    next_state        <= PRECHARGE;
                    ras_counter_req   <= false;
                    precharge_started <= true;
                else
                    next_state        <= REFRESH_RAS;
                    ras_counter_req   <= true;
                    precharge_started <= false;
                end if;
            when PRECHARGE =>
                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                if precharge_counter = i_config.precharge_threshold then
                    precharge_started <= false;

                    if not initialized and init_refresh_counter < i_config.init_refresh_threshold then
                        init_refresh_counter <= init_refresh_counter + 1;
                        next_state           <= REFRESH_START;
                        initialized          <= false;
                    else
                        init_refresh_counter <= (others => '0');
                        initialized          <= true;

                        if i_cs_n = '1' then
                            next_state <= IDLE;
                        else
                            next_state <= ROW_ADDRESS_STROBE;
                        end if;
                    end if;
                else
                    precharge_started <= true;
                    next_state        <= PRECHARGE;
                end if;
            when IDLE =>
                o_dsack       <= '0';
                o_ras_n       <= '1';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                if refresh_req then
                    next_state <= REFRESH_START;
                elsif i_cs_n = '0' then
                    next_state <= ROW_ADDRESS_STROBE;
                else
                    next_state <= IDLE;
                end if;
            when ROW_ADDRESS_STROBE =>
                o_dsack       <= '0';
                o_ras_n       <= '0';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '0';

                open_row_addr <= i_row_addr;
                next_state    <= ROW_ACTIVE;
            when ROW_ACTIVE =>
                o_dsack       <= '0';
                o_ras_n       <= '0';
                o_cas_n       <= '1';
                o_we_n        <= '1';
                o_oe_n        <= '1';
                o_mux_col_sel <= '1';

                if refresh_req then
                    next_state <= PRECHARGE;
                elsif i_cs_n = '0' then
                    if i_row_addr /= open_row_addr then
                        next_state <= PRECHARGE;
                    else
                        next_state <= READ_WRITE;
                    end if;
                else
                    next_state <= ROW_ACTIVE;
                end if;
            when READ_WRITE =>
                o_dsack       <= '1';
                o_ras_n       <= '0';
                o_cas_n       <= '0';
                o_we_n        <= i_we_n;
                o_oe_n        <= i_oe_n;
                o_mux_col_sel <= '1';

                if i_cs_n = '1' then
                    next_state <= ROW_ACTIVE;
                else
                    next_state <= READ_WRITE;
                end if;
        end case;
    end process;

end architecture;
