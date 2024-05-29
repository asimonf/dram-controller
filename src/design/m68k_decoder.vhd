library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

-- This decoder is made for a 68020 compatible bus.
-- 
-- The address word can be described as the following:
-- 
--              (                   (Address Word)                  )
--              |<--                ADDRESS_WIDTH                -->|
--              |                                                   |
--              |<-  (Block Address)  ->/<--  BASE_BLOCK_WIDTH   -->|
--              /                                                   \
--      ADDRESS_WIDTH - 1                                            0
--

entity m68k_decoder is
    generic (
        BASE_BLOCK_WIDTH   : integer := 20; -- 1 MiB block
        IO_BASE_BLOCK      : integer := 64; -- Always one block in length
        IO_SELECTS         : integer := 1;  -- # of select outputs, all contiguous
        MEM_BLOCK_CAPACITY : integer := 128);
    port (
        i_reset_n : in std_logic;
        i_clk     : in std_logic;

        i_as_n : in std_logic;
        i_addr : in sys_address_t;
        i_siz  : in std_logic_vector(1 downto 0);
        i_rw_n : in std_logic;
        i_fc   : in std_logic_vector(2 downto 0);

        o_we_n : out byte_sel_vector_t;
        o_oe_n : out byte_sel_vector_t;

        o_io_cs_n  : out std_logic_vector(IO_SELECTS - 1 downto 0);
        o_mem_cs_n : out std_logic);
end m68k_decoder;

architecture behavioral of m68k_decoder is
    function MemBase return integer is
    begin
        return 2 ** (ADDRESS_WIDTH - BASE_BLOCK_WIDTH) - MEM_BLOCK_CAPACITY;
    end function MemBase;

    function InMemSpace(
        sys_address : sys_address_t
    ) return boolean is
        variable addr_block : integer range 0 to 2 ** (ADDRESS_WIDTH - BASE_BLOCK_WIDTH) - 1;
    begin
        addr_block := to_integer(unsigned(sys_address(ADDRESS_WIDTH - 1 downto BASE_BLOCK_WIDTH)));

        return addr_block >= MemBase;
    end function InMemSpace;

    function InIOSpace(
        sys_address : sys_address_t;
        io_sel      : integer
    ) return boolean is
        variable addr_block : integer range 0 to 2 ** (ADDRESS_WIDTH - BASE_BLOCK_WIDTH) - 1;
    begin
        addr_block := to_integer(unsigned(sys_address(ADDRESS_WIDTH - 1 downto BASE_BLOCK_WIDTH)));

        return addr_block >= (IO_BASE_BLOCK + io_sel) and addr_block < IO_BASE_BLOCK + io_sel + 1;
    end function InIOSpace;

    -- 32-bit port selectors
    signal uub : std_logic;
    signal umb : std_logic;
    signal lmb : std_logic;
    signal llb : std_logic;

    -- 16-bit port selectors
    signal ub : std_logic;
    signal lb : std_logic;

    -- 8-bit port selector
    signal b : std_logic;

    -- byte selector
    signal uub_sel_n : std_logic;
    signal umb_sel_n : std_logic;
    signal lmb_sel_n : std_logic;
    signal llb_sel_n : std_logic;

    -- others
    signal cpu_cycle : std_logic;
    signal cs_n      : std_logic;
    signal io_cs_n   : std_logic_vector(IO_SELECTS - 1 downto 0);
    signal mem_cs_n  : std_logic;
begin
    -- Data words are expected to be up to 32-bits so address blocks must have at least 4 bytes
    assert BASE_BLOCK_WIDTH >= 2;
    -- Ensure that base is smaller than the width of the address
    assert BASE_BLOCK_WIDTH < ADDRESS_WIDTH;
    -- Prevent collisions
    assert IO_BASE_BLOCK + IO_SELECTS < MemBase;
    -- 68K CPUs are 32-bit processors
    assert ADDRESS_WIDTH <= 32;
    -- Ensure at least one IO signal exists
    assert IO_SELECTS > 0;

    -- Logic
    cpu_cycle <= i_fc(2) and i_fc(1) and i_fc(0);

    o_io_cs_n  <= io_cs_n;
    o_mem_cs_n <= mem_cs_n;

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

    ub <= uub or lmb;
    lb <= umb or llb;

    b <= uub or umb or lmb or llb;

    uub_sel_n <= not uub or not ub or not b or cs_n;
    umb_sel_n <= not umb or not ub or not b or cs_n;
    lmb_sel_n <= not lmb or not lb or not b or cs_n;
    llb_sel_n <= not llb or not lb or not b or cs_n;

    o_we_n(3) <= uub_sel_n or i_rw_n;
    o_we_n(2) <= umb_sel_n or i_rw_n;
    o_we_n(1) <= lmb_sel_n or i_rw_n;
    o_we_n(0) <= llb_sel_n or i_rw_n;

    o_oe_n(3) <= uub_sel_n or not i_rw_n;
    o_oe_n(2) <= umb_sel_n or not i_rw_n;
    o_oe_n(1) <= lmb_sel_n or not i_rw_n;
    o_oe_n(0) <= llb_sel_n or not i_rw_n;

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset_n = '0' or cpu_cycle = '1' or i_as_n = '1' then
                cs_n     <= '1';
                io_cs_n  <= (others => '1');
                mem_cs_n <= '1';
            else
                cs_n     <= '0';
                io_cs_n  <= (others => '1');
                mem_cs_n <= '1';

                for i in 0 to 2 ** IO_SELECTS - 1 loop
                    io_cs_n(i) <= '0' when InIOSpace(i_addr, i) else '1';
                end loop;

                mem_cs_n <= '0' when InMemSpace(i_addr) else '1';
            end if;
        end if;
    end process;
end architecture;
