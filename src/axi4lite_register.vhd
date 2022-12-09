library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi4lite_register is
    Generic (
        DATA_WIDTH : integer := 32;
        RESET_VALUE : std_logic_vector := (others => '0'));
    Port (
        clk      : IN STD_LOGIC;
        reset    : IN STD_LOGIC;
        enable   : IN STD_LOGIC;
        wstrb    : IN STD_LOGIC_VECTOR(DATA_WIDTH/8-1 downto 0);
        data_in  : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        data_out : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := RESET_VALUE);
end axi4lite_register;

architecture Behavioral of axi4lite_register is
    signal data_reg : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := RESET_VALUE;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to DATA_WIDTH/8-1 loop
                if reset = '1' then
                    data_reg(i*8+7 downto i*8) <= RESET_VALUE(i*8+7 downto i*8);
                elsif enable = '1' and wstrb(i) = '1' then
                    data_reg(i*8+7 downto i*8) <= data_in(i*8+7 downto i*8);
                else
                    data_reg(i*8+7 downto i*8) <= data_reg(i*8+7 downto i*8);
                end if;
            end loop;
        end if;
    end process;
    
    data_out <= data_reg;
end Behavioral;
