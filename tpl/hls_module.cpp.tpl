#include <ap_int.h>
void [dict get $specdata ip_name] (
    // AXI4-Lite registers

% foreach register [dict get $specdata registers] {
    ap_uint<[dict get $register width]>& [dict get $register name]Axil,

% }
    // IP ports

% set registers [dict get $specdata registers]
% for {set register_index 0} {$register_index < [llength $registers]} {incr register_index} {
% set register [lindex $registers $register_index]
%   set bitfields [dict get $register bitfields]
%   for {set bitfield_index 0} {$bitfield_index < [llength $bitfields]} {incr bitfield_index} {
%     set bitfield [lindex $bitfields $bitfield_index]
%     if {[dict get $bitfield io_direction] == "out"} {
%       set by_reference "&"
%     } else {
%       set by_reference ""
%     }
%     if {[expr $bitfield_index + 1] >= [llength $bitfields] && [expr $register_index + 1] >= [llength $registers]} {
%       set last ""
%     } else {
%       set last ","
%     }
    ap_uint<[dict get ${bitfield} width]>${by_reference} [dict get $bitfield name]${last}

%   }
% }
) {
    #pragma HLS INTERFACE s_axilite port=return
    // AXI4-Lite registers

% foreach register [dict get $specdata registers] {
%   set port [dict get $register name]
    #pragma HLS INTERFACE s_axilite port=${port}Axil

%   if {[dict get $register io_direction] == "in"} {
    #pragma HLS INTERFACE ap_none port=${port}Axil

%   }
% }
    // IP ports

% foreach register [dict get $specdata registers] {
%   foreach bitfield [dict get $register bitfields] {
    #pragma HLS INTERFACE ap_none port=[dict get $bitfield name] register

%   }
% }
    // Map ports to register bitfields

% foreach register [dict get $specdata registers] {
%   foreach bitfield [dict get $register bitfields] {
%     if {[dict get $bitfield io_direction] == "in"} {
    [dict get $register name]Axil.range([dict get $bitfield high_bit], [dict get $bitfield low_bit]) = [dict get $bitfield name];

%     } else {
    [dict get $bitfield name] = [dict get $register name]Axil.range([dict get $bitfield high_bit], [dict get $bitfield low_bit]);

%     }
%   }
% }
}