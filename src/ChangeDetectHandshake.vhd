----------------------------------------------------------------------------------
-- Company: Digilent Inc
-- Engineer: Arthur Brown 
-- 
-- Create Date: 07/12/2022 02:53:59 PM
-- Module Name: ChangeDetect - Behavioral
-- Project Name: axi4lite_ip_gen
-- Description: 
--   This module wraps a HandshakeData module to pass data across a clock domain crossing whenever incoming data changes.
--     It asserts the Push signal whenever a change is detected on the iData line if the Handshaker is ready to accept
--     a new piece of data, otherwise, it asserts an internal "Extend" signal which will ensure that Push is asserted 
--     at the next available opportunity
--   Since this module doesn't include a FIFO to store and forward all incoming Data transitions, states coming into 
--     iData are not necessarily reproduced on the oData line.
--     Don't use this in "high-speed" situations where every sample passed to this must be forwarded.
--     oValid is asserted whenever a new value is loaded into the oData register.
--   A pair of asynchronous active-high resets are accepted, one for each clock domain. Registers to control the Push
--     and change-detect logic are synchronous with the input clock and are reset by aiReset.
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ChangeDetectHandshake is
    Generic (
        kDataWidth : natural := 8
    );
    Port (
        InClk : in STD_LOGIC;
        OutClk : in STD_LOGIC;
        iData : in STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
        oData : out STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
        iRdy : out STD_LOGIC;
        oValid : out STD_LOGIC;
        aiReset : in STD_LOGIC;
        aoReset : in STD_LOGIC
    );
end ChangeDetectHandshake;

architecture Behavioral of ChangeDetectHandshake is
    component HandshakeData is
        generic (
            kDataWidth : natural := 8
        );
        port (
            InClk : in STD_LOGIC;
            OutClk : in STD_LOGIC;
            iData : in STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
            oData : out STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
            iPush : in STD_LOGIC;
            iRdy : out STD_LOGIC;
            oAck : in STD_LOGIC := '1';
            oValid : out STD_LOGIC;
            aiReset : in std_logic;
            aoReset : in std_logic
        );
    end component;
    
    signal iExtend : STD_LOGIC;
    signal iCompare : STD_LOGIC;
    signal iPush : STD_LOGIC;
    signal iRdyInternal : STD_LOGIC;
    signal iDataInternal : STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
    
begin
    iPush <= (iCompare or iExtend) and iRdyInternal;
    iRdy <= iRdyInternal;
    iCompare <= '1' when iData /= iDataInternal else '0';
    
    HandshakeDataInst: HandshakeData 
    generic map (
        kDataWidth => kDataWidth
    )
    port map(
        InClk => InClk,
        OutClk => OutClk,
        iData => iData,
        oData => oData,
        iPush => iPush,
        iRdy => iRdyInternal,
        oAck => '1', -- don't apply any backpressure
        oValid => oValid,
        aiReset => aiReset,
        aoReset => aoReset
    );
    
    StoreData: process(aiReset, InClk)
    begin
       if (aiReset = '1') then
          iDataInternal <= (others => '0');
       elsif Rising_Edge(InClk) then
          iDataInternal <= iData;
       end if;
    end process StoreData;
    
    GenerateExtend: process(aiReset, InClk)
    begin
       if (aiReset = '1') then
          iExtend <= '0';
       elsif Rising_Edge(InClk) then
          if iRdyInternal = '1' then
             iExtend <= '0';
          elsif iCompare = '1' then
             iExtend <= '1';
          end if;
       end if;
    end process GenerateExtend;
end Behavioral;
