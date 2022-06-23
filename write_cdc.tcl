set script_dir [file dirname [file normalize [info script]]]
source ${script_dir}/util.tcl

set outfile_path ${script_dir}/out/cdc.vhd
set tplfile_path ${script_dir}/tpl/cdc.vhd.tpl
set specfile_path ${script_dir}/tpl/example.json

#script has no calling context, so set up data for testing
package require json

source [file join $script_dir util.tcl]

# load json data
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

# fixme; only handles last interface
set interface [dict get $specdata axi4lite_interface]
set num_regs [expr [llength [dict get $specdata registers]] + [dict get $interface reserved_addresses]]

set addr_width [clog2 $num_regs]
set module_name [file rootname [file tail $specfile_path]]
set hls_module ZmodScopeConfig

proc get_prefix {specdata clock_name} {
    foreach clock [dict get $specdata clocks] {
        if {[dict get $clock name] == $clock_name} {
            return [dict get $clock prefix]
        }
    }
    return ""
}

set cdc_domain_pairs [list]
set cdc_signals [dict create]
foreach from_domain [dict get $specdata clocks] {
    set subdict [dict create]
    foreach to_domain [dict get $specdata clocks] {
        dict set subdict [dict get $to_domain name] [list]
    }
    dict set cdc_signals [dict get $from_domain name] $subdict

}

proc signal_insert {signal key1 key2 cdc_signals} {
    # since tcl generally doesn't return by reference, pull the lower level dict out of the one containing it, set it's value, and then set it back into the container
    
    set d1 [dict get $cdc_signals $key1]
    set d2 [dict get $d1 $key2]
    
    lappend d2 $signal

    dict set d1 $key2 $d2
    dict set cdc_signals $key1 $d1

    return $cdc_signals
}

foreach register [dict get $specdata registers] {
    foreach bitfield [dict get $register bitfields] {
        if {[dict get $bitfield access_type] == "ro"} {
            set io_direction in
            set from_domain [dict get $interface clock_domain]
            set to_domain [dict get $bitfield clock_domain]
        } else {
            set io_direction out
            set to_domain [dict get $interface clock_domain]
            set from_domain [dict get $bitfield clock_domain]
        }
        set bitfield_name [dict get $bitfield name]
        # make a list of the clock domains that signals are synchronous with, then fill that with signals
        
        if {$from_domain == $to_domain} {
            set cdc_type none
        } else {
            # each cdc consists of three signals, one output from the hls module, one flop, and one synchronous to the end domain
            set cdc_type single_bit
            set sig [dict create]
            dict set sig register [dict get $register name]
            dict set sig bitfield [dict get $bitfield name]
            dict set sig io_direction $io_direction
            puts "[dict get $bitfield name] : $io_direction"
            dict set sig width [expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit] + 1]
            dict set sig name ${bitfield_name}
            dict set sig clock_domain [dict get $bitfield clock_domain]
            set cdc_signals [signal_insert $sig $from_domain $to_domain $cdc_signals]
        }

        # set up information for handshake controllers
        set pair [dict create]
        dict set pair from_domain $from_domain
        dict set pair to_domain $to_domain 
        dict set pair from_prefix [get_prefix $specdata $from_domain]
        dict set pair to_prefix [get_prefix $specdata $to_domain]
        if {[lsearch $cdc_domain_pairs $pair] == -1} {
            lappend cdc_domain_pairs $pair
        }
    }
}

# load the template
set cdc_tmpl [open $tplfile_path r]
set tmpl [read $cdc_tmpl]
close $cdc_tmpl

# do the thing
set out [list]
eval [substify $tmpl out]

set f [open $outfile_path w]
puts $f $out
close $f