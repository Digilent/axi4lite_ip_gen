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
%   set prefix [get_prefix $specdata [dict get $register clock_domain]]
%   foreach bitfield [dict get $register bitfields] {
%     if {[dict get $register access_type] == "ro"} {
%       set io_direction IN
%     } else {
%       set io_direction OUT
%     }
%     set port_high_bit [expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit]]
%     set bitfield_name ${prefix}[dict get $bitfield name]
%     if {${port_high_bit} == 0} {
%       set type "STD_LOGIC"
%     } else {
%       set type "STD_LOGIC_VECTOR (${port_high_bit} downto 0)"
%     }
    ${bitfield_name} : ${io_direction} ${type};

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
component ${module_name}_axilite is
generic (

% set addr_width [get_axi4lite_interface_addr_width $specdata]
% set interface [dict get $specdata axi4lite_interface]
    ADDR_WIDTH : INTEGER := C_[string toupper [dict get $interface name]]_ADDR_WIDTH;
    DATA_WIDTH : INTEGER := C_[string toupper [dict get $interface name]]_DATA_WIDTH
);
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    awaddr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    awvalid : IN STD_LOGIC;
    awready : OUT STD_LOGIC;
    wdata : IN STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    wstrb : IN STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH/8-1 downto 0);
    wvalid : IN STD_LOGIC;
    wready : OUT STD_LOGIC;
    bresp : OUT STD_LOGIC_VECTOR(1 downto 0);
    bvalid : OUT STD_LOGIC;
    bready : IN STD_LOGIC;
    araddr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    arvalid : IN STD_LOGIC;
    arready : OUT STD_LOGIC;
    rdata : OUT STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);
    rresp : OUT STD_LOGIC_VECTOR(1 downto 0);
    rvalid : OUT STD_LOGIC;
    rready : IN STD_LOGIC;

% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
%   set name "Reg${i}"
%   set type "STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0)"
%   if {[dict get $register access_type] != "wo"} {
    ${name}_i : IN ${type};

%   }
%   if {[dict get $register access_type] != "ro"} {
    ${name}_o : OUT ${type};

%   }
% }
    interrupt: OUT STD_LOGIC
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

component ChangeDetectHandshake is
generic (
    kDataWidth : natural := 8
);
port (
    InClk : in STD_LOGIC;
    OutClk : in STD_LOGIC;
    iData : in STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
    oData : out STD_LOGIC_VECTOR (kDataWidth-1 downto 0);
    iRdy : out STD_LOGIC;
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

% set axi_clk [dict get $interface clock_domain]
% set axi_clk_prefix [get_prefix $specdata ${axi_clk}]
% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
%   set access [dict get ${register} access_type]
%   set clock_domain [dict get ${register} clock_domain]
%   set clock_prefix [get_prefix $specdata ${clock_domain}]
signal ${clock_prefix}Reg${i} : STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);

%   if {${axi_clk_prefix} != ${clock_prefix}} {
signal ${axi_clk_prefix}Reg${i} : STD_LOGIC_VECTOR(C_[string toupper [dict get $interface name]]_DATA_WIDTH-1 downto 0);

%   }
% }

begin

--- Instantiate register file core
${module_name}_axilite_inst: ${module_name}_axilite port map(
    clk => [dict get $interface clock_domain],
    reset => ${axi_clk_prefix}Rst,

% set prefix [get_prefix $specdata [dict get $interface clock_domain]]
% set registers [dict get $specdata registers]
% for {set register_index 0} {$register_index < [llength $registers]} {incr register_index} {
%   set register [lindex $registers $register_index]
%   set bitfields [dict get $register bitfields]
%   set name "Reg${register_index}"
%   if {[dict get $register access_type] != "wo"} {
    ${name}_i => ${prefix}${name},

%   }
%   if {[dict get $register access_type] != "ro"} {
    ${name}_o => ${prefix}${name},

%   }
% }
% set interface_name [string tolower [dict get $interface name]]

    awvalid   => ${interface_name}_AWVALID,
    awready   => ${interface_name}_AWREADY,
    awaddr    => ${interface_name}_AWADDR,
    wvalid    => ${interface_name}_WVALID,
    wready    => ${interface_name}_WREADY,
    wdata     => ${interface_name}_WDATA,
    wstrb     => ${interface_name}_WSTRB,
    arvalid   => ${interface_name}_ARVALID,
    arready   => ${interface_name}_ARREADY,
    araddr    => ${interface_name}_ARADDR,
    rvalid    => ${interface_name}_RVALID,
    rready    => ${interface_name}_RREADY,
    rdata     => ${interface_name}_RDATA,
    rresp     => ${interface_name}_RRESP,
    bvalid    => ${interface_name}_BVALID,
    bready    => ${interface_name}_BREADY,
    bresp     => ${interface_name}_BRESP,
    interrupt => ${prefix}Interrupt
);

--- Create synchronous resets for each clock

% foreach clock_domain [dict get $specdata clocks] {
%   set clock [dict get $clock_domain name] 
%   if {$clock == [dict get ${interface} clock_domain]} {
[get_prefix $specdata ${clock}]Rst_n <= [dict get ${interface} reset];
[get_prefix $specdata ${clock}]Rst <= not [dict get ${interface} reset];

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

--- Instantiate handshake clock domain crossing modules

% set axi_clk [dict get $interface clock_domain]
% set axi_clk_prefix [get_prefix $specdata ${axi_clk}]
% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
%   set access [dict get ${register} access_type]
%   set clock_domain [dict get ${register} clock_domain]
%   set clock_prefix [get_prefix $specdata ${clock_domain}]
%   if {$access != "wo"} {

---- Register $i input path
---- trigger handshake push on any difference in the input bus

%     if {${clock_domain} != ${axi_clk}} {
reg${i}_from_${clock_domain}_to_${axi_clk}_InstHandshake: ChangeDetectHandshake 
generic map (
    kDataWidth => C_[string toupper [dict get $interface name]]_DATA_WIDTH
)
port map(
    InClk => ${clock_domain},
    OutClk => ${axi_clk},
    iData => ${clock_prefix}Reg${i},
    oData => ${axi_clk_prefix}Reg${i},
    iRdy => open,
    oValid => open,
    aiReset => ${clock_prefix}Rst,
    aoReset => ${axi_clk_prefix}Rst
);

%     }
%     set unused_bits [dict create]; # set up a dict to look up which bits are used by bitfields and which arent
%     for {set bit_i 0} {$bit_i < 32} {incr bit_i} {
%       dict set unused_bits $bit_i 1
%     }
%     set bitfields [dict get ${register} bitfields]
%     foreach bitfield $bitfields {
%       set bitfield_name [dict get $bitfield name]
%       set bitfield_high [dict get $bitfield high_bit]
%       set bitfield_low [string trim [dict get $bitfield low_bit]]; # trimming required due to a likely bug in the tcl json package
%       set width [expr $bitfield_high - $bitfield_low + 1]
%       if {$width > 1} {
${clock_prefix}Reg${i}(${bitfield_high} downto ${bitfield_low}) <= ${clock_prefix}${bitfield_name};

%       } else {
${clock_prefix}Reg${i}(${bitfield_low}) <= ${clock_prefix}${bitfield_name};

%       }
%       for {set bit_i $bitfield_low} {$bit_i <= $bitfield_high} {incr bit_i} {
%         dict set unused_bits $bit_i 0; # bit is used; clear its dict entry
%       }
%     }
%     foreach {bit unused} $unused_bits {
%       if {$unused} {
%          # potential improvement, look ahead and use downto ranges
${clock_prefix}Reg${i}(${bit}) <= '0';

%       }
%     }
%   }
%   if {$access != "ro"} {

---- Register $i output path

%     if {${axi_clk} != ${clock_domain}} {
---- trigger handshake on interrupt
reg${i}_from_${axi_clk}_to_${clock_domain}_InstHandshake: HandshakeData 
generic map (
    kDataWidth => C_[string toupper [dict get $interface name]]_DATA_WIDTH
)
port map(
    InClk => ${axi_clk},
    OutClk => ${clock_domain},
    iData => ${axi_clk_prefix}Reg${i},
    oData => ${clock_prefix}Reg${i},
    iPush => ${axi_clk_prefix}Interrupt,
    iRdy => open,
    oAck => '1',
    oValid => open,
    aiReset => ${axi_clk_prefix}Rst,
    aoReset => ${clock_prefix}Rst
);

%     }
%     set bitfields [dict get ${register} bitfields]
%     foreach bitfield $bitfields {
%       set bitfield_name [dict get $bitfield name]
%       set bitfield_high [dict get $bitfield high_bit]
%       set bitfield_low [string trim [dict get $bitfield low_bit]]; # trimming required due to a likely bug in the tcl json package
%       set width [expr $bitfield_high - $bitfield_low + 1]
%       if {$width > 1} {
${clock_prefix}${bitfield_name} <= ${clock_prefix}Reg${i}(${bitfield_high} downto ${bitfield_low});

%       } else {
${clock_prefix}${bitfield_name} <= ${clock_prefix}Reg${i}(${bitfield_low});

%       }
%     }
%   }
% }

end Behavioral;