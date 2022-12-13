library IEEE;
use ieee.std_logic_1164.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use ieee.numeric_std.all;

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

-- Each register gets an input port if read is allowed and an output port if write is allowed
-- This core is bitfield agnostic

% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
%   set type "STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)"
%   set access [dict get $register access_type]
%   if {${access} != "wo"} {
    Reg${i}_i : IN ${type};

%   }
%   if {${access} != "ro"} {
    Reg${i}_o : OUT ${type};

%   }
% }
    interrupt: OUT STD_LOGIC
    );
end;

architecture Behavioral of ${module_name}_axilite is
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
    ADDR_WIDTH : INTEGER := 2;
    NUM_REGS : INTEGER := 4
);
port (
    address : IN STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
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
    RESET_VALUE : STD_LOGIC_VECTOR(31 downto 0) := (others => '0')
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
    signal arreg_word : STD_LOGIC_VECTOR(ADDR_WIDTH-3 downto 0);

    signal awreg_en : STD_LOGIC;
    signal wreg_en : STD_LOGIC;
    signal arreg_en : STD_LOGIC;

    signal reg_en : STD_LOGIC_VECTOR(NUM_REGS-1 downto 0);

    signal arready_int : STD_LOGIC;
    signal arvalid_int : STD_LOGIC;
    signal araddr_int : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    signal rdata_int : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    
    signal awready_int : STD_LOGIC;
    signal awvalid_int : STD_LOGIC;
    signal awaddr_int : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);

% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
    signal reg${i}_enable : STD_LOGIC;

%   set access [dict get $register access_type]
%   if {${access} == "wo"} {
    signal Reg${i}_i : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

%   }
%   if {${access} != "ro"} {
    signal Reg${i}_int : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

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
            awvalid  => awvalid_int,
            awready  => awready_int,
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
            arvalid  => arvalid_int,
            arready  => arready_int,
            rvalid   => rvalid,
            rready   => rready,
            arreg_en => arreg_en
        );

    addr_decode_inst: address_decode
        generic map (
            NUM_REGS => NUM_REGS,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            address => awreg,
            reg_en => reg_en
        );
        
    -- Write address
    awbuffer: skid_buffer
        generic map (
            DATA_WIDTH => ADDR_WIDTH
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

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                awreg <= (others => '0');
            elsif awreg_en = '1' then
                awreg <= awaddr_int;
            else
                awreg <= awreg;
            end if;
        end if;
    end process;
    
    -- Read address register
    -- skid buffer may not be necessary if master can be guaranteed to never send two read address beats in subsequent cycles,
    -- this is likely the case, and might be built into the AXI spec
    -- without further research, its inclusion guarantees that address will not be dropped
    arbuffer: skid_buffer
        generic map (
            DATA_WIDTH => ADDR_WIDTH
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

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                arreg <= (others => '0');
            elsif arreg_en = '1' then
                arreg <= araddr_int;
            else
                arreg <= arreg;
            end if;
        end if;
    end process;
    
    arreg_word <= arreg(arreg'length-1 downto 2);

    -- Read data mux
    -- read data is not skid-buffered because the two-cycle loop time of the control logic guarantees that data will never be updated on two consecutive cycles
    rdata <= rdata_int;
    
% set sensitivity [list]
% lappend sensitivity arreg_word
% for {set i 0} {$i < [llength [dict get $specdata registers]]} {incr i} {
%   lappend sensitivity Reg${i}_i
% }

    rdata_mux: process([join ${sensitivity} ", "])
    begin

% set first "if"
% for {set i 0} {$i < [llength [dict get $specdata registers]]} {incr i} {
%   if {${addr_width} == 2} {
%     1-reg core not supported
%   } else {
        ${first} arreg_word = std_logic_vector(to_unsigned(${i}, arreg_word'length)) then
            rdata_int <= Reg${i}_i;

%   }
%   set first "elsif"
% }
        else
            rdata_int <= (others => '0');
        end if;
    end process rdata_mux;
    
    -- Individual registers

% set registers [dict get $specdata registers]
% for {set i 0} {$i < [llength $registers]} {incr i} {
%   set register [lindex $registers $i]
%   set access_type [dict get $register access_type]
%   if {$access_type != "ro"} {
    -- Register ${i} instantiation
    reg${i}_enable <= reg_en(${i}) and wreg_en;
    Reg${i}_inst: axi4lite_register
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            RESET_VALUE => std_logic_vector(to_unsigned(0, DATA_WIDTH))
        )
        port map (
            clk      => clk,
            reset    => reset,
            enable   => reg${i}_enable,
            wstrb    => wstrb,
            data_in  => wdata,
            data_out => Reg${i}_int
        );
    Reg${i}_o <= Reg${i}_int;
    Reg${i}_i <= Reg${i}_int;

%   } elseif {${access_type} == "wo"} {
    Reg${i}_i <= Reg${i}_o; -- Loop back on write-only registers

%   }
% }

-- Fire interrupt on a one cycle delay after write strobes, matching wdata to reg port latency
-- No masking of spurious strobes (like for a write to a RO register) is currently done
process (clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            interrupt <= '0';
        elsif wreg_en = '1' then
            interrupt <= '1';
        else
            interrupt <= '0';
        end if;
    end if;
end process;

end Behavioral;