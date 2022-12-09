library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity base_register is
    Generic (
        DATA_WIDTH : integer := 1;
        RESET_VALUE : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'));
    Port (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        en : IN STD_LOGIC;
        data_i : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        data_o : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0));
end base_register;

architecture Behavioral of base_register is
begin
    decode: process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                data_o <= RESET_VALUE;
            elsif en = '1' then
                data_o <= data_i;
            else
                data_o <= data_o;
            end if;
        end if;
    end process decode;
end Behavioral;
