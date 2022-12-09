library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity address_decode is
    Generic (
        NUM_REGS : integer := 4;
        ADDR_WIDTH : integer := 4);
    Port (
        address : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        reg_en : out STD_LOGIC_VECTOR(NUM_REGS-1 downto 0));
end address_decode;

architecture Behavioral of address_decode is

begin
    decode: process (address)
    begin
        for i in 0 to NUM_REGS-1 loop
            if address = std_logic_vector(to_unsigned(i, address'length)) then
                reg_en(i) <= '1';
            else
                reg_en(i) <= '0';
            end if;
        end loop;
    end process decode;
end Behavioral;
