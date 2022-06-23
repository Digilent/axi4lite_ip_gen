library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity $module_name is
generic (

% set interface [dict get $specdata axi4lite_interface]
    C_[string toupper [dict get $interface name]]_ADDR_WIDTH : INTEGER := ${addr_width};
    C_[string toupper [dict get $interface name]]_DATA_WIDTH : INTEGER := 32
    );
port (

% foreach clock [dict get $specdata clocks] {
    [dict get $clock name] : IN STD_LOGIC;

% }
    [dict get $interface reset] : IN STD_LOGIC;

% foreach register [dict get $specdata registers] {
%   foreach bitfield [dict get $register bitfields] {
%     if {[dict get $bitfield access_type] == "ro"} {
%       set io_direction IN
%       set prefix [get_prefix $specdata [dict get $bitfield clock_domain]]
%     } else {
%       set io_direction OUT
%       set prefix [get_prefix $specdata [dict get $bitfield clock_domain]]
%     }
%     if {[dict get $bitfield high_bit] != [dict get $bitfield low_bit]} {
    ${prefix}[dict get $bitfield name] : $io_direction STD_LOGIC_VECTOR ([dict get $bitfield high_bit] downto [dict get $bitfield low_bit]);

%     } else {
    ${prefix}[dict get $bitfield name] : $io_direction STD_LOGIC;

%     }
%   }
% }

    [dict get $interface name]_AWVALID : IN STD_LOGIC;
    [dict get $interface name]_AWREADY : OUT STD_LOGIC;
    [dict get $interface name]_AWADDR : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_ADDR_WIDTH-1 downto 0);
    [dict get $interface name]_WVALID : IN STD_LOGIC;
    [dict get $interface name]_WREADY : OUT STD_LOGIC;
    [dict get $interface name]_WDATA : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    [dict get $interface name]_WSTRB : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH/8-1 downto 0);
    [dict get $interface name]_ARVALID : IN STD_LOGIC;
    [dict get $interface name]_ARREADY : OUT STD_LOGIC;
    [dict get $interface name]_ARADDR : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_ADDR_WIDTH-1 downto 0);
    [dict get $interface name]_RVALID : OUT STD_LOGIC;
    [dict get $interface name]_RREADY : IN STD_LOGIC;
    [dict get $interface name]_RDATA : OUT STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    [dict get $interface name]_RRESP : OUT STD_LOGIC_VECTOR (1 downto 0);
    [dict get $interface name]_BVALID : OUT STD_LOGIC;
    [dict get $interface name]_BREADY : IN STD_LOGIC;
    [dict get $interface name]_BRESP : OUT STD_LOGIC_VECTOR (1 downto 0)
    );
end;

architecture Behavioral of $module_name is
component $hls_module is
generic (

% set interface [dict get $specdata axi4lite_interface]
    C_[string toupper [dict get $interface name]]_ADDR_WIDTH : INTEGER := ${addr_width};
    C_[string toupper [dict get $interface name]]_DATA_WIDTH : INTEGER := 32
    );
port (

    ap_clk : IN STD_LOGIC;
    ap_rst_n : IN STD_LOGIC;

% foreach register [dict get $specdata registers] {
%   foreach bitfield [dict get $register bitfields] {
%     if {[dict get $bitfield access_type] == "ro"} {
%       set io_direction IN
%     } else {
%       set io_direction OUT
%     }
%     set prefix [get_prefix $specdata [dict get $interface clock_domain]]
%     if {[dict get $bitfield high_bit] != [dict get $bitfield low_bit]} {
    [dict get $bitfield name] : $io_direction STD_LOGIC_VECTOR ([dict get $bitfield high_bit] downto [dict get $bitfield low_bit]);

%     } else {
    [dict get $bitfield name] : $io_direction STD_LOGIC;

%     }
%   }
% }

    [dict get $interface name]_AWVALID : IN STD_LOGIC;
    [dict get $interface name]_AWREADY : OUT STD_LOGIC;
    [dict get $interface name]_AWADDR : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_ADDR_WIDTH-1 downto 0);
    [dict get $interface name]_WVALID : IN STD_LOGIC;
    [dict get $interface name]_WREADY : OUT STD_LOGIC;
    [dict get $interface name]_WDATA : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    [dict get $interface name]_WSTRB : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH/8-1 downto 0);
    [dict get $interface name]_ARVALID : IN STD_LOGIC;
    [dict get $interface name]_ARREADY : OUT STD_LOGIC;
    [dict get $interface name]_ARADDR : IN STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_ADDR_WIDTH-1 downto 0);
    [dict get $interface name]_RVALID : OUT STD_LOGIC;
    [dict get $interface name]_RREADY : IN STD_LOGIC;
    [dict get $interface name]_RDATA : OUT STD_LOGIC_VECTOR (C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    [dict get $interface name]_RRESP : OUT STD_LOGIC_VECTOR (1 downto 0);
    [dict get $interface name]_BVALID : OUT STD_LOGIC;
    [dict get $interface name]_BREADY : IN STD_LOGIC;
    [dict get $interface name]_BRESP : OUT STD_LOGIC_VECTOR (1 downto 0);
    interrupt : OUT STD_LOGIC
    );
end component;

component ResetBridge is
    Generic (
        kPolarity : std_logic := '1');
    Port (
        aRst : in STD_LOGIC; -- asynchronous reset; active-high, if kPolarity=1
        OutClk : in STD_LOGIC;
        oRst : out STD_LOGIC);
end component;

component ack_gen is
port (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    inLoad : IN STD_LOGIC_VECTOR (0 downto 0);
    inReq : IN STD_LOGIC_VECTOR (0 downto 0);
    outAck : OUT STD_LOGIC_VECTOR (0 downto 0);
    outValid : OUT STD_LOGIC_VECTOR (0 downto 0);
    outLoadData : OUT STD_LOGIC_VECTOR (0 downto 0) );
end component;

component req_gen is
port (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    inSend : IN STD_LOGIC_VECTOR (0 downto 0);
    inAck : IN STD_LOGIC_VECTOR (0 downto 0);
    outReq : OUT STD_LOGIC_VECTOR (0 downto 0);
    outReady : OUT STD_LOGIC_VECTOR (0 downto 0);
    outLoadData : OUT STD_LOGIC_VECTOR (0 downto 0) );
end component;

signal [get_prefix $specdata [dict get $interface clock_domain]]Interrupt : STD_LOGIC;

% foreach clock_domain [dict get $specdata clocks] {
signal [get_prefix $specdata [dict get ${clock_domain} name]]Rst_n : STD_LOGIC;

% }
-- CDC flags

% foreach cdc $cdc_domain_pairs {
%   set from [dict get $cdc from_prefix]
%   set to [dict get $cdc to_prefix]
signal ${to}${from}AckCDC : STD_LOGIC;
signal ${from}${to}ReqCDC : STD_LOGIC;
signal ${from}LoadData : STD_LOGIC;
signal ${from}${to}LoadData : STD_LOGIC;

%   if {[dict get $cdc to_domain] == [dict get $interface clock_domain]} {
signal ${from}${to}Ready : STD_LOGIC;

%   }
% }

% set interface_prefix [get_prefix $specdata [dict get $interface clock_domain]]
% foreach {from_domain to_domains} $cdc_signals {
%   foreach {to_domain signals} $to_domains {
%     foreach {signal} $signals {
%       set io_direction [dict get $signal io_direction]
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {$io_direction == "in"} {
%         if {[dict get $signal width] != 1} {
signal ${domain_prefix}${signal_name}_CDC : STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0);
signal ${interface_prefix}${signal_name} : STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0);

%         } else {
signal ${domain_prefix}${signal_name}_CDC : STD_LOGIC;
signal ${interface_prefix}${signal_name} : STD_LOGIC;

%         }
%       } else {
%         if {[dict get $signal width] != 1} {
signal ${domain_prefix}${signal_name}Int : STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0);
signal ${interface_prefix}${signal_name}_CDC : STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0);
signal ${interface_prefix}${signal_name} : STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0);

%         } else {
signal ${domain_prefix}${signal_name}Int : STD_LOGIC;
signal ${interface_prefix}${signal_name}_CDC : STD_LOGIC;
signal ${interface_prefix}${signal_name} : STD_LOGIC;

%         }
%       }
%     }
%   }
% }

begin

-- Instantiate HLS IP
${hls_module}_inst: ${hls_module} port map(
    ap_clk => [dict get $interface clock_domain],
    ap_rst_n => [dict get $interface reset],

% set prefix [get_prefix $specdata [dict get $interface clock_domain]]
% foreach register [dict get $specdata registers] {
%   foreach bitfield [dict get $register bitfields] {
%     set bitfield_name [dict get $bitfield name]
%     if {[dict get $bitfield high_bit] != [dict get $bitfield low_bit]} {
    ${bitfield_name}(0) => ${prefix}${bitfield_name},

%     } else {
    ${bitfield_name} => ${prefix}${bitfield_name},

%     }
%   }
% }

    [dict get $interface name]_AWVALID => [dict get $interface name]_AWVALID,
    [dict get $interface name]_AWREADY => [dict get $interface name]_AWREADY,
    [dict get $interface name]_AWADDR => [dict get $interface name]_AWADDR,
    [dict get $interface name]_WVALID => [dict get $interface name]_WVALID,
    [dict get $interface name]_WREADY => [dict get $interface name]_WREADY,
    [dict get $interface name]_WDATA => [dict get $interface name]_WDATA,
    [dict get $interface name]_WSTRB => [dict get $interface name]_WSTRB,
    [dict get $interface name]_ARVALID => [dict get $interface name]_ARVALID,
    [dict get $interface name]_ARREADY => [dict get $interface name]_ARREADY,
    [dict get $interface name]_ARADDR => [dict get $interface name]_ARADDR,
    [dict get $interface name]_RVALID => [dict get $interface name]_RVALID,
    [dict get $interface name]_RREADY => [dict get $interface name]_RREADY,
    [dict get $interface name]_RDATA => [dict get $interface name]_RDATA,
    [dict get $interface name]_RRESP => [dict get $interface name]_RRESP,
    [dict get $interface name]_BVALID => [dict get $interface name]_BVALID,
    [dict get $interface name]_BREADY => [dict get $interface name]_BREADY,
    [dict get $interface name]_BRESP => [dict get $interface name]_BRESP,
    interrupt => ${prefix}Interrupt
);

--- Create synchronous resets for each clock

% foreach clock_domain [dict get $specdata clocks] {
%   set clock [dict get $clock_domain name] 
%   if {$clock == [dict get ${interface} clock_domain]} {
[get_prefix $specdata ${clock}]Rst_n <= [dict get ${interface} reset];

%   } else {
[dict get ${interface} clock_domain]_to_${clock}_rst: ResetBridge generic map(
    kPolarity => '0'
)
port map (
    aRst => [dict get ${interface} reset],
    outClk => ${clock},
    oRst => [get_prefix $specdata ${clock}]Rst_n
);

%   }
% }

--- Map Internal ports to Int signals
% foreach {from_domain to_domains} $cdc_signals {
%   foreach {to_domain signals} $to_domains {
%     foreach signal $signals {
%       if {$from_domain == [dict get $interface clock_domain]} {
%         set prefix [get_prefix $specdata $to_domain]
%       } else {
%         set prefix [get_prefix $specdata $from_domain]
%       }
%       if {[dict get $signal io_direction] == "out"} {

${prefix}[dict get $signal name] <= ${prefix}[dict get $signal name]Int;
%       }
%     }
%   }
% }


-- CDC flags
-- todo: check if these are actually used or not

% set interface_domain [dict get $interface clock_domain]
% set interface_prefix [get_prefix $specdata $interface_domain]
% foreach clock_domain [dict get $specdata clocks] {
%   set domain [dict get $clock_domain name]
%   if {[dict get $interface clock_domain] != ${domain}} {
%     set domain_prefix [get_prefix $specdata ${domain}]

-- Handshake request from ${interface_domain} to ${domain}
${interface_domain}_to_${domain}_req: req_gen port map(
    ap_clk => ${interface_domain},
    ap_rst => ${interface_prefix}Rst_n,
    inSend(0) => ${interface_prefix}Interrupt, -- output path fed by HLS interrupt
    inAck(0) => ${domain_prefix}${interface_prefix}AckCDC,
    outReq(0) => ${interface_prefix}${domain_prefix}ReqCDC,
    outLoadData(0) => ${interface_prefix}${domain_prefix}LoadData
);
-- Handshake acknowledge from ${domain} to ${interface_domain}
${interface_domain}_to_${domain}_ack: ack_gen port map(
    ap_clk => ${domain},
    ap_rst => ${domain_prefix}Rst_n,
    inLoad(0) => '1',
    inReq(0) => ${interface_prefix}${domain_prefix}ReqCDC,
    outAck(0) => ${domain_prefix}${interface_prefix}AckCDC,
    outLoadData(0) => ${domain_prefix}LoadData
);

-- Handshake request from ${domain} to ${interface_domain}
-- It will send the data whenever it is ready
${domain}_to_${interface_domain}_req: req_gen port map(
    ap_clk => ${domain},
    ap_rst => ${domain_prefix}Rst_n,
    inSend(0) => ${domain_prefix}${interface_prefix}Ready, -- input path continuously writes back
    inAck(0) => ${interface_prefix}${domain_prefix}AckCDC,
    outReady(0) => ${domain_prefix}${interface_prefix}Ready,
    outReq(0) => ${domain_prefix}${interface_prefix}ReqCDC,
    outLoadData(0) => ${domain_prefix}${interface_prefix}LoadData
);
-- Handshake acknowledge from ${interface_domain} to ${domain}
${domain}_to_${interface_domain}_ack: ack_gen port map(
    ap_clk => ${interface_domain},
    ap_rst => ${interface_prefix}Rst_n,
    inLoad(0) => '1',
    inReq(0) => ${domain_prefix}${interface_prefix}ReqCDC,
    outAck(0) => ${interface_prefix}${domain_prefix}AckCDC,
    outLoadData(0) => ${interface_prefix}LoadData
);


%   }
% }

-- Handle CDC registers

% foreach {from_domain to_domains} $cdc_signals {
%   set from_prefix [get_prefix $specdata $from_domain]
%   foreach {to_domain signals} $to_domains {
%     if {[llength $signals] == 0} {continue}

-- Register status flags in ${from_domain} domain before clock domain crossing to ${to_domain}
${from_domain}_to_${to_domain}_pre_cdc: process(${from_domain}, ${from_prefix}Rst_n)
begin
    if (rising_edge(${from_domain})) then
        if (${from_prefix}Rst_n = '0') then

%     foreach {signal} $signals {
%       set io_direction [dict get $signal io_direction]
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {$io_direction == "in"} {
%         set left_prefix ${domain_prefix}
%         set right_prefix ${interface_prefix}
%       } else {
%         set left_prefix ${interface_prefix}
%         set right_prefix ${domain_prefix}
%       }
%       if {[dict get $signal width] != 1} {
            ${left_prefix}${signal_name}_CDC <= (others => '0');

%       } else {
            ${left_prefix}${signal_name}_CDC <= '0';

%       }
%     }
        else
            if (${left_prefix}${right_prefix}LoadData = '1') then

%     foreach {signal} $signals {
%       set io_direction [dict get $signal io_direction]
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {$io_direction == "in"} {
%         set prefix ${domain_prefix}
%       } else {
%         set prefix ${interface_prefix}
%       }
            ${prefix}${signal_name}_CDC <= ${prefix}${signal_name};
            end if;
        end if;
    end if;

%     }
end process;

%   }
% }

% foreach {from_domain to_domains} $cdc_signals {
%   set from_prefix [get_prefix $specdata $from_domain]
%   foreach {to_domain signals} $to_domains {
%     set to_prefix [get_prefix $specdata $to_domain]
%     if {[llength $signals] == 0} {continue}

-- Register configuration in ${to_domain} domain after clock domain crossing from ${from_domain}
${from_domain}_to_${to_domain}_post_cdc: process(${to_domain}, ${to_prefix}Rst_n)
begin
    if(rising_edge(${to_domain})) then
        if (${to_prefix}Rst_n = '0') then

%     foreach {signal} $signals {
%       set io_direction [dict get $signal io_direction]
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {$io_direction == "in"} {
%         set left_prefix ${interface_prefix}
%         set right_prefix ${domain_prefix}
%         set postfix ""
%       } else {
%         set left_prefix ${domain_prefix}
%         set right_prefix ${interface_prefix}
%         set postfix "Int"
%       }
%       if {[dict get $signal width] != 1} {
            ${left_prefix}${signal_name}${postfix} <= (others => '0');

%       } else {
            ${left_prefix}${signal_name}${postfix} <= '0';

%       }
%     }
        else
            if (${left_prefix}LoadData = '1') then

%     foreach {signal} $signals {
%       set io_direction [dict get $signal io_direction]
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {$io_direction == "in"} {
%         set left_prefix ${interface_prefix}
%         set right_prefix ${domain_prefix}
%         set postfix ""
%       } else {
%         set left_prefix ${domain_prefix}
%         set right_prefix ${interface_prefix}
%         set postfix "Int"
%       }
                ${left_prefix}${signal_name}${postfix} <= ${right_prefix}${signal_name}_CDC;
            end if;
        end if;
    end if;

%     }
end process;

%   }
% }

end Behavioral;