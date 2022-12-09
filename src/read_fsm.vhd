library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity read_fsm is
    Port (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        arvalid : IN STD_LOGIC;
        arready : OUT STD_LOGIC;
        rvalid : OUT STD_LOGIC;
        rready : IN STD_LOGIC;
        arreg_en : OUT STD_LOGIC);
end read_fsm;

architecture Behavioral of read_fsm is
    type STATE_TYPE is (s_await_address, s_await_data);
    signal state : STATE_TYPE := s_await_address;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= s_await_address;
            else
                case state is
                    when s_await_address =>
                        if arvalid = '1' then
                            state <= s_await_data;
                        else
                            state <= state;
                        end if;
                    when s_await_data =>
                        if rready = '1' then
                            state <= s_await_address;
                        else
                            state <= state;
                        end if;
                end case;
            end if;
        end if;
    end process;

    process (state) begin
        case state is
            when s_await_address =>
                rvalid <= '0';
                arready <= '1';
                arreg_en <= '1';
            when s_await_data =>
                rvalid <= '1';
                arready <= '0';
                arreg_en <= '0';
        end case;
    end process;
end Behavioral;
