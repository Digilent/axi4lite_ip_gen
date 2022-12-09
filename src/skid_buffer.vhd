library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity skid_buffer is
    Generic (
        DATA_WIDTH : integer := 32);
    Port (
        clk      : IN STD_LOGIC;
        reset    : IN STD_LOGIC;
        aready   : OUT STD_LOGIC;
        avalid   : IN STD_LOGIC;
        adata    : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        bready   : IN STD_LOGIC;
        bvalid   : OUT STD_LOGIC;
        bdata    : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0));
end skid_buffer;

architecture Behavioral of skid_buffer is
    signal rvalid : STD_LOGIC;
    signal rdata : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal load : STD_LOGIC;
    signal unload : STD_LOGIC;
begin
    bvalid <= avalid or rvalid;
    bdata <= rdata when rvalid = '1' else adata;
    aready <= bready;
    load <= (not bready) and avalid;
    unload <= (not avalid) and bready;
    
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rdata <= std_logic_vector(to_unsigned(0, rdata'length));
            elsif load = '1' then
                rdata <= adata;
            else
                rdata <= rdata;
            end if;
        end if;
    end process;
    
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rvalid <= '0';
            elsif unload = '1' then
                rvalid <= '0';
            elsif load = '1' then
                rvalid <= '1';
            else
                rvalid <= rvalid;
            end if;
        end if;
    end process;
end Behavioral;
