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

component ResetBridge is
generic (
    kPolarity : std_logic := '1'
);
port (
    aRst : in STD_LOGIC; -- asynchronous reset; active-high, if kPolarity=1
    OutClk : in STD_LOGIC;
    oRst : out STD_LOGIC
);
end component;

-- HLS interrupt flag
signal [get_prefix $specdata [dict get $interface clock_domain]]Interrupt : STD_LOGIC;

-- Reset signals for each clock domain

% foreach clock_domain [dict get $specdata clocks] {
signal [get_prefix $specdata [dict get ${clock_domain} name]]Rst_n : STD_LOGIC;
signal [get_prefix $specdata [dict get ${clock_domain} name]]Rst : STD_LOGIC;

% }

-- Internal signals for ports

% set interface_prefix [get_prefix $specdata [dict get $interface clock_domain]]
% foreach {domain domain_ports} $ports_by_domain_and_direction {
%   foreach {direction cdc_group} $domain_ports {
%     foreach signal [dict get $cdc_group ports] {
%       set domain_prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       set signal_name [dict get $signal name]
%       if {[dict get $signal width] != 1} {
%         set signal_type {STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0)}
%       } else {
%         set signal_type {STD_LOGIC}
%       }
signal ${interface_prefix}${signal_name} : ${signal_type};

%       if {$direction == "out"} {
signal ${domain_prefix}${signal_name}Int : ${signal_type};

%       }
%     }
%   }
% }


begin

--- Instantiate HLS register file core

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
[get_prefix $specdata ${clock}]Rst <= not [get_prefix $specdata ${clock}]Rst_n;

%   }
% }

--- Map external output ports to internal signals

% foreach {from_domain to_domains} $cdc_signals {
%   foreach {to_domain signals} $to_domains {
%     foreach signal $signals {
%       set prefix [get_prefix $specdata [dict get $signal clock_domain]]
%       if {[dict get $signal io_direction] == "out"} {

${prefix}[dict get $signal name] <= ${prefix}[dict get $signal name]Int;

%       }
%     }
%   }
% }

--- Instantiate handshake clock domain crossing modules

% foreach {domain domain_ports} $ports_by_domain_and_direction {
%   foreach {direction cdc_group} $domain_ports {
%     set low_index 0
%     if {$direction == "in"} {
%       set iprefix [get_prefix $specdata $domain]
%       set oprefix [get_prefix $specdata [dict get $interface clock_domain]]
%       set opostfix ""
%       set pushsignal {'1'}
%       set inclk $domain
%       set outclk [dict get $interface clock_domain]
%     } else {
%       set opostfix "Int"
%       set pushsignal "[get_prefix $specdata [dict get $interface clock_domain]]Interrupt"
%       set inclk [dict get $interface clock_domain]
%       set outclk $domain
%     }
%     set iprefix [get_prefix $specdata $inclk]
%     set oprefix [get_prefix $specdata $outclk]

-- Handshake CDC from ${inclk} to ${outclk}
${inclk}_to_${outclk}_cdc: HandshakeData 
generic map (
    kDataWidth => [dict get $cdc_group num_bits]
)
port map(
    InClk => ${inclk},
    OutClk => ${outclk},

%     foreach port [dict get $cdc_group ports] {
%       set width [dict get $port width]
%       if {$width > 1} {
    iData([expr $low_index + $width - 1] downto $low_index) => ${iprefix}[dict get $port name],
    oData([expr $low_index + $width - 1] downto $low_index) => ${oprefix}[dict get $port name]${opostfix},

%       } else {
    iData($low_index) => ${iprefix}[dict get $port name],
    oData($low_index) => ${oprefix}[dict get $port name]${opostfix},

%       }
%       set low_index [expr $low_index + $width]
%     }
% 
    iPush => ${pushsignal},
    iRdy => open, -- unused? no point in applying backpressure to the hls core, axi lite transactions should be infrequent enough
    oAck => '1', -- tie high, don't apply any backpressure to this
    oValid => open, -- unused? no downstream register write enable is needed
    aiReset => ${iprefix}Rst,
    aoReset => ${oprefix}Rst
);

%   }
% }

end Behavioral;