library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ${module_name}_top is
generic (

% set addr_width [get_axi4lite_interface_addr_width $specdata]
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
%     if {[dict get $register access_type] == "ro"} {
%       set io_direction IN
%       set prefix [get_prefix $specdata [dict get $bitfield clock_domain]]
%     } else {
%       set io_direction OUT
%       set prefix [get_prefix $specdata [dict get $bitfield clock_domain]]
%     }
%     set bitfield_name ${prefix}[dict get $bitfield name]
    ${bitfield_name} : $io_direction STD_LOGIC_VECTOR ([expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit]] downto 0);

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

architecture Behavioral of ${module_name}_top is
component $hls_module is
generic (

% set addr_width [get_axi4lite_interface_addr_width $specdata]
% set interface [dict get $specdata axi4lite_interface]
    C_[string toupper [dict get $interface name]]_ADDR_WIDTH : INTEGER := ${addr_width};
    C_[string toupper [dict get $interface name]]_DATA_WIDTH : INTEGER := 32
);
port (
    ap_clk : IN STD_LOGIC;
    ap_rst_n : IN STD_LOGIC;

% foreach {domain domain_ports} $ports_by_domain_and_direction {
%   foreach {direction cdc_group} $domain_ports {
%     foreach bitfield [dict get $cdc_group ports] {
%       set io_direction [string toupper [dict get $bitfield io_direction]]
%       set prefix [get_prefix $specdata [dict get $interface clock_domain]]
%       set internal_name [dict get $bitfield internal_name]
    ${internal_name} : $io_direction STD_LOGIC_VECTOR ([expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit]] downto 0);

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
%       set signal_type "STD_LOGIC_VECTOR ([expr [dict get $signal width] - 1] downto 0)"
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
% foreach {domain domain_ports} $ports_by_domain_and_direction {
%   foreach {direction cdc_group} $domain_ports {
%     foreach bitfield [dict get $cdc_group ports] {
%       set bitfield_name ${prefix}[dict get $bitfield name]
%       set internal_name [dict get $bitfield internal_name]
    ${internal_name} => ${bitfield_name},

%     }
%   }
% }
% set interface_name [string tolower [dict get $interface name]]
    ${interface_name}_AWVALID => [dict get $interface name]_AWVALID,
    ${interface_name}_AWREADY => [dict get $interface name]_AWREADY,
    ${interface_name}_AWADDR => [dict get $interface name]_AWADDR,
    ${interface_name}_WVALID => [dict get $interface name]_WVALID,
    ${interface_name}_WREADY => [dict get $interface name]_WREADY,
    ${interface_name}_WDATA => [dict get $interface name]_WDATA,
    ${interface_name}_WSTRB => [dict get $interface name]_WSTRB,
    ${interface_name}_ARVALID => [dict get $interface name]_ARVALID,
    ${interface_name}_ARREADY => [dict get $interface name]_ARREADY,
    ${interface_name}_ARADDR => [dict get $interface name]_ARADDR,
    ${interface_name}_RVALID => [dict get $interface name]_RVALID,
    ${interface_name}_RREADY => [dict get $interface name]_RREADY,
    ${interface_name}_RDATA => [dict get $interface name]_RDATA,
    ${interface_name}_RRESP => [dict get $interface name]_RRESP,
    ${interface_name}_BVALID => [dict get $interface name]_BVALID,
    ${interface_name}_BREADY => [dict get $interface name]_BREADY,
    ${interface_name}_BRESP => [dict get $interface name]_BRESP,
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

% foreach {domain domain_ports} $ports_by_domain_and_direction {
%   set cdc_group [dict get $domain_ports "out"]
%   foreach port [dict get $cdc_group ports] {
%     set prefix [get_prefix $specdata [dict get $port clock_domain]]
${prefix}[dict get $port name] <= ${prefix}[dict get $port name]Int;

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
%     foreach port [dict get $cdc_group ports] {
%       set port_name [dict get $port name]
-- Handshake CDC for ${port_name} from ${inclk} to ${outclk}
${port_name}_from_${inclk}_to_${outclk}_InstHandshake: HandshakeData 
generic map (
    kDataWidth => [dict get $port width]
)
port map(
    InClk => ${inclk},
    OutClk => ${outclk},
    iData => ${iprefix}${port_name},
    oData => ${oprefix}${port_name}${opostfix},
    iPush => ${pushsignal},
    iRdy => open, -- unused? no point in applying backpressure to the hls core, axi lite transactions should be infrequent enough
    oAck => '1', -- tie high, don't apply any backpressure to this
    oValid => open, -- unused? no downstream register write enable is needed
    aiReset => ${iprefix}Rst,
    aoReset => ${oprefix}Rst
);

%     }
%   }
% }

end Behavioral;