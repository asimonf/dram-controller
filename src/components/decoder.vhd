library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    generic (
        BASE_BLOCK_WIDTH : integer := 20;
        ADDRESS_WIDTH    : integer := 28;
        BANK_WIDTH       : integer := 0;
        COLUMN_WIDTH     : integer := 10);
    port (
        i_reset_n : in std_logic;

        i_as_n : in std_logic;
        i_addr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
        i_siz  : in std_logic_vector(1 downto 0);
        i_rw_n : in std_logic;
        i_fc   : in std_logic_vector(2 downto 0);

        i_base_addr : in std_logic_vector(ADDRESS_WIDTH - BASE_BLOCK_WIDTH - 1 downto 0);
        i_base_size : in std_logic_vector(ADDRESS_WIDTH - BASE_BLOCK_WIDTH - 1 downto 0);

        o_row_addr : out std_logic_vector(ADDRESS_WIDTH - COLUMN_WIDTH - BANK_WIDTH - 1 downto 0);
        o_col_addr : out std_logic_vector(COLUMN_WIDTH - 1 downto 0);

        o_bank_sel : out std_logic_vector((2 ** BANK_WIDTH) - 1 downto 0);

        o_we_n : out std_logic_vector(3 downto 0);
        o_oe_n : out std_logic_vector(3 downto 0);

        o_cs_n : out std_logic);
end decoder;

architecture behavioral of decoder is
    signal uub : std_logic;
    signal umb : std_logic;
    signal lmb : std_logic;
    signal llb : std_logic;
begin
    assert ADDRESS_WIDTH > BASE_BLOCK_WIDTH;
    assert ADDRESS_WIDTH >= BANK_WIDTH + COLUMN_WIDTH;
    assert ADDRESS_WIDTH <= 32;
    assert BANK_WIDTH >= 0;
    assert COLUMN_WIDTH > 0;
    assert BASE_BLOCK_WIDTH >= 2;

    uub <= not i_addr(1) and not i_addr(0);

    umb <= (not i_addr(1) and i_addr(0)) or
        (not i_addr(1) and not i_addr(0) and not (not i_siz(1) and i_siz(0)));

    lmb <= (i_addr(1) and not i_addr(0)) or
        (not i_addr(1) and i_addr(0) and not (not i_siz(1) and i_siz(0))) or
        (not i_addr(1) and not i_addr(0) and ((not i_siz(1) and not i_siz(0)) or (i_siz(1) and i_siz(0))));

    llb <= (i_addr(1) and i_addr(0)) or
        (i_addr(1) and not i_addr(0) and not (not i_siz(1) and i_siz(0))) or
        (not i_addr(1) and i_addr(0) and ((not i_siz(1) and not i_siz(0)) or (i_siz(1) and i_siz(0)))) or
        (not i_addr(1) and not i_addr(0) and not (not i_siz(1) and not i_siz(0)));

    o_row_addr <= i_addr(ADDRESS_WIDTH - 1 downto COLUMN_WIDTH + BANK_WIDTH);
    o_col_addr <= i_addr(COLUMN_WIDTH - 1 downto 0);

    multi_bank : if BANK_WIDTH > 0 generate
    begin
        process (i_addr)
            variable bank_addr : std_logic_vector(BANK_WIDTH - 1 downto 0);
            variable bank_bit  : integer;
        begin
            bank_addr := i_addr(COLUMN_WIDTH + BANK_WIDTH - 1 downto COLUMN_WIDTH);
            bank_bit  := to_integer(unsigned(bank_addr));

            o_bank_sel           <= (others => '0');
            o_bank_sel(bank_bit) <= '1';
        end process;
    end generate multi_bank;

    single_bank : if BANK_WIDTH = 0 generate
    begin
        o_bank_sel <= (others => '1');
    end generate single_bank;

    process (i_reset_n, i_as_n)
        variable addr_block  : unsigned(ADDRESS_WIDTH - BASE_BLOCK_WIDTH - 1 downto 0) := (others => '0');
        variable addr_offset : unsigned(ADDRESS_WIDTH - BASE_BLOCK_WIDTH - 1 downto 0) := (others => '0');
        variable addr_match  : boolean;
        variable cs_n        : std_logic;
    begin
        if i_as_n = '1' or i_reset_n = '0' or i_fc = "111" then
            o_we_n <= (others => '1');
            o_oe_n <= (others => '1');
            o_cs_n <= '1';
        else
            addr_block := unsigned(i_addr(ADDRESS_WIDTH - 1 downto BASE_BLOCK_WIDTH));
            addr_match := addr_block >= unsigned(i_base_addr);

            if addr_match then
                addr_offset := addr_block - unsigned(i_base_addr);

                if addr_offset < unsigned(i_base_addr) then
                    cs_n := '1';
                else
                    cs_n := '0';
                end if;
            else
                cs_n := '1';
            end if;

            o_we_n(3) <= not uub or i_rw_n or o_cs_n;
            o_we_n(2) <= not umb or i_rw_n or o_cs_n;
            o_we_n(1) <= not lmb or i_rw_n or o_cs_n;
            o_we_n(0) <= not llb or i_rw_n or o_cs_n;

            o_oe_n(3) <= not uub or not i_rw_n or o_cs_n;
            o_oe_n(2) <= not umb or not i_rw_n or o_cs_n;
            o_oe_n(1) <= not lmb or not i_rw_n or o_cs_n;
            o_oe_n(0) <= not llb or not i_rw_n or o_cs_n;

            o_cs_n <= cs_n;
        end if;
    end process;
end architecture;
