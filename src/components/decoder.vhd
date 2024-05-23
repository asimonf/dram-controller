library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This decoder is made for a 68020 compatible bus. It supports bank interleaving,
-- if the bank width is larger than 0. For practical limitations, maybe limit yourself to
-- only a few banks like 2 (bank width = 1), but if the outputs are buffered you could
-- have more than 2 banks.
-- 
-- The address word can be described as the following:
-- 
--              (                   (Address Word)                  )
--              |<--                ADDRESS_WIDTH                -->|
--              |                                                   |
--              |<- ROW_WIDTH ->/<- BANK_WIDTH ->/<- COLUMN_WIDTH ->|
--              |                                                   |
--              |<-  (Block Address)  ->/<--  BASE_BLOCK_WIDTH   -->|
--              /                                                   \
--      ADDRESS_WIDTH - 1                                            0
--
-- - The row address bits are the first ROW_WIDTH bits of the address word
-- - The selected bank bits (if defined) are going to be the the next BANK_WIDTH bits of the word after the row address
-- - The column address are going to be the next bits after the bank until the end.

entity decoder is
    generic (
        BASE_BLOCK_WIDTH : integer := 20;
        ADDRESS_WIDTH    : integer := 28;
        COLUMN_WIDTH     : integer := 10;
        BANK_WIDTH       : integer := 0;
        ROW_WIDTH        : integer := 18;
        CAPACITY_MB      : integer := 128);
    port (
        i_reset_n : in std_logic;

        i_as_n : in std_logic;
        i_addr : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
        i_siz  : in std_logic_vector(1 downto 0);
        i_rw_n : in std_logic;
        i_fc   : in std_logic_vector(2 downto 0);

        o_row_addr : out std_logic_vector(ROW_WIDTH - 1 downto 0);
        o_col_addr : out std_logic_vector(COLUMN_WIDTH - 1 downto 0);

        o_bank     : out integer range 0 to (2 ** BANK_WIDTH) - 1;
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
    -- ** Assertions **

    -- All addresses must have a column width and a row width larger than 0
    assert ROW_WIDTH > 0
    report "Error: ROM_WIDTH must be greated than 0"
        severity error;
    assert COLUMN_WIDTH > 0
    report "Error: COLUMN_WIDTH must be greated than 0"
        severity error;

    -- Bank can be disabled by specifying it to be 0, but it must be positive otherwise
    assert BANK_WIDTH >= 0
    report "Error: BANK_WIDTH must be greated than or equal to 0"
        severity error;

    -- Data words are expected to be 32-bits so address blocks must have at least 4 bytes
    assert BASE_BLOCK_WIDTH >= 2
    report "Error: BASE_BLOCK_WIDTH must be greated than or equal to 2"
        severity error;
    assert BASE_BLOCK_WIDTH < ADDRESS_WIDTH
    report "Error: BASE_BLOCK_WIDTH must be smaller than ADDRESS_WIDTH"
        severity error;

    -- While nothing specific about this design makes it incompatible with larger addresses,
    -- I won't take into consideration larger addresses when designing this
    assert ADDRESS_WIDTH <= 32
    report "Error: ADDRESS_WIDTH must be smaller or equal to 32"
        severity error;

    -- Make sure the config makes sense
    assert ADDRESS_WIDTH = ROW_WIDTH + BANK_WIDTH + COLUMN_WIDTH
    report "Error: ADDRESS_WIDTH must be to the sum of ROW_WIDTH, BANK_WIDTH and COLUMN_WIDTH"
        severity error;

    -- ** Combinational Logic **

    -- Decode SIZ1, SIZ0, A1 and A0 to determine which bytes are selected from the 32-bit data word
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

    -- Decode column and row addresses
    o_row_addr <= i_addr(ADDRESS_WIDTH - 1 downto ADDRESS_WIDTH - ROW_WIDTH);
    o_col_addr <= i_addr(COLUMN_WIDTH - 1 downto 0);

    -- ** Processes **

    -- If multiple banks are permitted, decode the bank
    multi_bank : if BANK_WIDTH > 0 generate
    begin
        process (i_addr)
            variable bank_addr : std_logic_vector(BANK_WIDTH - 1 downto 0);
            variable bank_bit  : integer range 0 to (2 ** BANK_WIDTH) - 1;
        begin
            bank_addr := i_addr(COLUMN_WIDTH + BANK_WIDTH - 1 downto COLUMN_WIDTH);
            bank_bit  := to_integer(unsigned(bank_addr));

            o_bank               <= bank_bit;
            o_bank_sel           <= (others => '0');
            o_bank_sel(bank_bit) <= '1';
        end process;
    end generate multi_bank;

    -- Otherwise just select the single bank available
    single_bank : if BANK_WIDTH = 0 generate
    begin
        o_bank     <= 0;
        o_bank_sel <= (others => '1');
    end generate single_bank;

    process (i_reset_n, i_as_n)
        constant block_base : integer := 2 ** (ADDRESS_WIDTH - BASE_BLOCK_WIDTH) - CAPACITY_MB;

        variable addr_block : integer range 0 to 2 ** (ADDRESS_WIDTH - BASE_BLOCK_WIDTH) - 1 := 0;
        variable cs_n       : std_logic;
    begin
        -- Do not decode CPU Cycles if selected or when being reset
        if i_as_n = '1' or i_reset_n = '0' or i_fc = "111" then
            o_we_n <= (others => '1');
            o_oe_n <= (others => '1');
            o_cs_n <= '1';
        else
            addr_block := to_integer(unsigned(i_addr(ADDRESS_WIDTH - 1 downto BASE_BLOCK_WIDTH)));

            if addr_block >= block_base then
                cs_n := '0';
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
