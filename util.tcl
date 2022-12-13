proc clog2 {num} {
    set value 0
    while {[expr 2 ** $value] < $num} {
        incr value
    }
    return $value
}

# https://wiki.tcl-lang.org/page/Templates+and+subst
proc substify {in {var OUT}} {
    set pos 0  
    foreach pair [regexp -line -all -inline -indices {^%.*$} $in] {
        lassign $pair from to
        set s [string range $in $pos [expr {$from-2}]]
        append script "append $var \[" [list subst $s] "]\n" \
                                    [string range $in [expr {$from+1}] $to] "\n"
        set pos [expr {$to+2}]
    }
    set s [string range $in $pos end]
    append script "append $var \[" [list subst $s] "]\n"
}

proc range2mask {high low} {
    set mask 0
    for {set i $low} {$i <= $high} {incr i} {
        set mask [expr $mask | (1 << $i)]
    }
    return $mask
}

proc get_prefix {specdata clock_name} {
    foreach clock [dict get $specdata clocks] {
        if {[dict get $clock name] == $clock_name} {
            return [dict get $clock prefix]
        }
    }
    return ""
}

# Workaround for the following warning.
# WARNING: [SYN 201-107] Renaming port name 'ExampleIp/Start' to 'ExampleIp/Start_r' to avoid the conflict with HDL keywords or other object names.
# Hardcodes a list of reserved port names and rules to rewrite them. Some initial testing shows that 
proc get_hls_portname {bitfield_name} {
    set reserved_names [list]
    lappend reserved_names "start"
    lappend reserved_names "begin"
    lappend reserved_names "end"
    set idx [lsearch $reserved_names [string tolower $bitfield_name]]
    if {$idx != -1} {
        # preserve original caps
        set bitfield_name "${bitfield_name}_r"
    }
    return $bitfield_name
}

proc get_register_addresses {specdata} {
    set address_info [list]
    set offset 0x0
    set width 4

    # set newreg [dict create]
    # dict set newreg name sync
    # dict set newreg width 0x4
    # dict set newreg offset $offset
    # set offset [format 0x%x [expr $offset + $width]]
    # lappend address_info $newreg

    foreach register [dict get $specdata registers] {
        set newreg [dict create]
        dict set newreg name [dict get $register name]
        dict set newreg width $width
        dict set newreg offset $offset
        set offset [format 0x%x [expr $offset + $width]]
        lappend address_info $newreg
    }

    return $address_info
}

proc find_register_offset_by_name {return_var address_info register_name} {
    global $return_var
    foreach address $address_info {
        puts $address
        if {[dict get $address name] == $register_name} {
            set $return_var [dict get $address offset]
            return 0
        }
    }
    return -1
}

proc get_num_words_in_address_space {specdata} {
    return [llength [dict get $specdata registers]]
}

proc get_axi4lite_interface_addr_width {specdata} {
    # HLS reserves 64 bits for each register for the user register file and 32 bits for each of its own registers, regardless of the actual used register size
    set bytes_per_word 4
    return [clog2 [expr [get_num_words_in_address_space $specdata] * $bytes_per_word]]
}