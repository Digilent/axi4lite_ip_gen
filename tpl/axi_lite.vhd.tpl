library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity ${module_name}_axilite is
generic (
    ADDR_WIDTH : INTEGER := ${addr_width};
    DATA_WIDTH : INTEGER := 32;
    NUM_REGS : INTEGER := ${num_regs}
    );
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    awaddr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    awvalid : IN STD_LOGIC;
    awready : OUT STD_LOGIC;

    wdata : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    wstrb : IN STD_LOGIC_VECTOR(DATA_WIDTH/8-1 downto 0);
    wvalid : IN STD_LOGIC;
    wready : OUT STD_LOGIC;

    bresp : OUT STD_LOGIC_VECTOR(1 downto 0);
    bvalid : OUT STD_LOGIC;
    bready : IN STD_LOGIC;
    
    araddr : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    arvalid : IN STD_LOGIC;
    arready : OUT STD_LOGIC;
    
    rdata : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    rresp : OUT STD_LOGIC_VECTOR(1 downto 0);
    rvalid : OUT STD_LOGIC;
    rready : IN STD_LOGIC;

% set registers [dict get $specdata registers]
% for {set register_index 0} {$register_index < [llength $registers]} {incr register_index} {
% set register [lindex $registers $register_index]
%   set bitfields [dict get $register bitfields]
%   for {set bitfield_index 0} {$bitfield_index < [llength $bitfields]} {incr bitfield_index} {
%     set bitfield [lindex $bitfields $bitfield_index]
%     set high_bit [expr [dict get ${bitfield} width]-1]
%     set name [dict get ${bitfield} name]
%     if {[dict get $bitfield access_type] != "wo"} {
    ${name}_i : IN STD_LOGIC_VECTOR(${high_bit} downto 0),

%     }
%     if {[dict get $bitfield access_type] != "ro"} {
    ${name}_o : OUT STD_LOGIC_VECTOR(${high_bit} downto 0),

%     }
%   }
% }

    interrupt: OUT STD_LOGIC
    );
end;

architecture Behavioral of ${module_name}_top is
component write_fsm is
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    awvalid : IN STD_LOGIC;
    awready : OUT STD_LOGIC;
    wvalid : IN STD_LOGIC;
    wready : OUT STD_LOGIC;
    bvalid : OUT STD_LOGIC;
    bready : IN STD_LOGIC;
    awreg_en : OUT STD_LOGIC;
    wreg_en : OUT STD_LOGIC
);
end component;

component read_fsm is
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    arvalid : IN STD_LOGIC;
    arready : OUT STD_LOGIC;
    rvalid : OUT STD_LOGIC;
    rready : IN STD_LOGIC;
    arreg_en : OUT STD_LOGIC
);
end component;

component address_decode is
generic (
    NUM_REGS : INTEGER := 4
);
port (
    address : IN STD_LOGIC_VECTOR(integer(ceil(log2(1.0*(NUM_REGS-1))))-1 downto 0);
    reg_en : OUT STD_LOGIC_VECTOR(NUM_REGS-1 downto 0)
);
end component;

component skid_buffer is
generic (
    DATA_WIDTH : INTEGER := 32
);
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    aready : OUT STD_LOGIC;
    avalid : IN STD_LOGIC;
    adata : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    bready : IN STD_LOGIC;
    bvalid : OUT STD_LOGIC;
    bdata : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
);
end component;

component axi4lite_register is
generic (
    DATA_WIDTH : INTEGER := 32;
    RESET_VALUE : INTEGER := 0
);
port (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    enable : IN STD_LOGIC;
    wstrb : IN  STD_LOGIC_VECTOR(DATA_WIDTH/8-1 downto 0);
    data_in : IN STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    data_out : OUT  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
);
end component;

    constant RESP_OKAY : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant RESP_EXOKAY : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant RESP_SLVERR : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant RESP_DECERR : STD_LOGIC_VECTOR(1 downto 0) := "11";

    signal awreg : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    signal arreg : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);

    signal awreg_en : STD_LOGIC;
    signal wreg_en : STD_LOGIC;
    signal arreg_en : STD_LOGIC;

    signal reg_en : STD_LOGIC_VECTOR(NUM_REGS-1 downto 0);

    signal arready_int : STD_LOGIC;
    signal arvalid_int : STD_LOGIC;
    signal araddr_int : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal rdata_int : STD_LOGIC;
    
    signal awready_int : STD_LOGIC;
    signal awvalid_int : STD_LOGIC;
    signal awaddr_int : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

% set registers [dict get $specdata registers]
% for {set register_index 0} {$register_index < [llength $registers]} {incr register_index} {
% set register [lindex $registers $register_index]
%   set bitfields [dict get $register bitfields]
    signal reg${register_index}_i : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal reg${register_index}_o : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

%   for {set bitfield_index 0} {$bitfield_index < [llength $bitfields]} {incr bitfield_index} {
%     set bitfield [lindex $bitfields $bitfield_index]
%     set high_bit [expr [dict get ${bitfield} width]-1]
%     set name [dict get ${bitfield} name]
%     if {[dict get $bitfield access_type] != "wo"} {
    signal ${name}_int : STD_LOGIC_VECTOR(${high_bit} downto 0);

%   }
% }

begin
    -- Always respond OKAY.
    -- SLVERRs could be implemented in future for (for ex) attempted writes to read-only registers.

    rresp <= RESP_OKAY;
    bresp <= RESP_OKAY;

    -- Control logic, one state machine each for the read and write channels, which control data flow through this module and handshake signals
    write_fsm_inst: write_fsm
        port map (
            clk      => clk,
            reset    => reset,
            awvalid  => awvalid,
            awready  => awready,
            wvalid   => wvalid,
            wready   => wready,
            bvalid   => bvalid,
            bready   => bready,
            awreg_en => awreg_en,
            wreg_en  => wreg_en
        );

    read_fsm_inst: read_fsm
        port map (
            clk      => clk,
            reset    => reset,
            arvalid  => arvalid,
            arready  => arready,
            rvalid   => rvalid,
            rready   => rready,
            arreg_en => arreg_en
        );

    addr_decode_inst: address_decode
        generic map (
            NUM_REGS => NUM_REGS
        )
        port map (
            address => awreg,
            reg_en => reg_en
        );
        
    -- Write address
    awbuffer: skid_buffer
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk    => clk,
            reset  => reset,
            aready => awready,
            avalid => awvalid,
            adata  => awaddr,
            bready => awready_int,
            bvalid => awvalid_int,
            bdata  => awaddr_int
        );

    awreg_inst: base_register
        generic map (
            DATA_WIDTH => ADDR_WIDTH,
            RESET_VALUE => (others => '0')
        )
        port map (
            clk    => clk,
            reset  => reset,
            en     => awreg_en,
            data_i => awaddr_int,
            data_o => awreg
        );
    
    -- Read address register
    -- skid buffer may not be necessary if master can be guaranteed to never send two read address beats in subsequent cycles,
    -- this is likely the case, and might be built into the AXI spec
    -- without further research, its inclusion guarantees that address will not be dropped
    arbuffer: skid_buffer
        generic map (
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk    => clk,
            reset  => reset,
            aready => arready,
            avalid => arvalid,
            adata  => araddr,
            bready => arready_int,
            bvalid => arvalid_int,
            bdata  => araddr_int
        );

    arreg_inst: base_register
        generic map (
            DATA_WIDTH => ADDR_WIDTH,
            RESET_VALUE => (others => '0')
        )
        port map (
            clk    => clk,
            reset  => reset,
            en     => arreg_en,
            data_i => araddr_int,
            data_o => arreg
        );
    
    -- Read data mux
    -- read data is not skid-buffered because the two-cycle loop time of the control logic guarantees that data will never be updated on two consecutive cycles
    rdata <= rdata_int;
    
    rdata_mux: process(all)
    begin
        case arreg is
% for {set i 0} {$i < [llength [dict get $specdata registers]]} {incr i} {
            when ${i}: => rdata_int <= reg${i}_i;

%   }
% }
            when others => rdata_int <= (others => '0');
        end case;
    end process rdata_mux;
    
    -- Individual registers
% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
    -- Register ${i} instantiation

    reg${i}_inst: axi4lite_register
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            RESET_VALUE => (others => '0')
        )
        port map (
            clk      => clk,
            reset    => reset,
            enable   => reg_en(${i}) and wreg_en,
            wstrb    => wstrb,
            data_in  => wdata,
            data_out => reg${i}_o
        );

    -- Register ${i} bitfield mapping
%   for {set bitfield_index 0} {$bitfield_index < [llength $bitfields]} {incr bitfield_index} {
%     set bitfield [lindex $bitfields $bitfield_index]
%     set width [dict get ${bitfield} width]
%     set high [dict get ${bitfield} high_bit]
%     set low [dict get ${bitfield} low_bit]
%     set name [dict get ${bitfield} name]
%     if {[dict get $bitfield access_type] != "wo"} {
    reg${i}_i[${high}:${low}] <= ${name}_int;

%     }
%     if {[dict get $bitfield access_type] != "ro"} {
    ${name}_int <= reg${i}_o[${high}:${low}];

%     }
%   }
% }

end Behavioral;