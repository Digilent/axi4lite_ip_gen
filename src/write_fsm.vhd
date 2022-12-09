library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity write_fsm is
    Port (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        
        awvalid  : in  STD_LOGIC;
        awready  : out STD_LOGIC;
        wvalid   : in  STD_LOGIC;
        wready   : out STD_LOGIC;
        bvalid   : out STD_LOGIC;
        bready   : in  STD_LOGIC;
        awreg_en : out STD_LOGIC;
        wreg_en  : out STD_LOGIC);
end write_fsm;

architecture Behavioral of write_fsm is
    type STATE_TYPE is (s_await_address, s_await_data, s_await_resp);
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
                        state <= s_await_data when awvalid = '1' else state;
                    when s_await_data =>
                        state <= s_await_resp when wvalid = '1' else state;
                    when s_await_resp =>
                        state <= s_await_address when bready = '1' else state;
                end case;
            end if;
        end if;
    end process;

    wready   <= '1' when state = s_await_data else '0';
    awready  <= '1' when state = s_await_address else '0';
    bvalid   <= '1' when state = s_await_resp else '0';
    awreg_en <= awready;
    wreg_en  <= wvalid and wready;
end Behavioral;
