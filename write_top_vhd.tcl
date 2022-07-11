# calling context must set this:
# set specfile_path ${script_dir}/examples/ExampleIp.json

set script_dir [file dirname [file normalize [info script]]]
source ${script_dir}/util.tcl

#script has no calling context, so set up data for testing
package require json

source [file join $script_dir util.tcl]

# load json data
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

set ip_name [dict get $specdata ip_name]
set outfile_path ${script_dir}/intermediates/${ip_name}/${ip_name}_top.vhd
set tplfile_path ${script_dir}/tpl/cdc.vhd.tpl

set module_name [file rootname [file tail $specfile_path]]
set hls_module [dict get $specdata ip_name]

# Set up nested dicts ordered such that the template can easily iterate through ports while instantiating CDC modules
#   ports_by_domain_and_direction is indexed first by the name of the non-AXI clock that the CDC is connected to,
#   then by the direction (in or out) of the CDC with respect to the AXI interface, then a final dict is provided with
#   a 'ports' field and a 'num_bits' field
#   ports lists the appropriate bitfields from the spec, with all of their spec fields intact and
#     io_direction and width fields added
#   num_bits contains the sum of the widths of all bitfields with that direction and clock domain

# [dict]
#   (clock_name): [dict]
#     in|out: [dict]
#       num_bits: int
#       ports: [list]
#         : bitfield
#           name: str
#           high_bit: int
#           low_bit: int
#           width: int
#           access_type: ro|rw|wo
#           io_direction: in|out
#           clock_domain: (clock_name)

set ports_by_domain_and_direction [dict create]
foreach domain [dict get $specdata clocks] {
    if {[dict get $domain name] != [dict get [dict get $specdata axi4lite_interface] clock_domain]} {
        set ports_by_direction [dict create]
        foreach direction {in out} {
            set cdc_group [dict create]
            dict set cdc_group num_bits 0
            dict set cdc_group ports [list]
            dict set ports_by_direction $direction $cdc_group
        }
        dict set ports_by_domain_and_direction [dict get $domain name] $ports_by_direction
    }
}
puts $ports_by_domain_and_direction

foreach register [dict get $specdata registers] {
    set access_type [dict get $register access_type]
    if {$access_type == "ro"} {
        set io_direction in
    } else {
        set io_direction out
    }
    foreach bitfield [dict get $register bitfields] {
        set bitfield_domain [dict get $bitfield clock_domain]
        set ports_by_direction [dict get $ports_by_domain_and_direction $bitfield_domain]
        
        set bitfield_width [expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit] + 1]
        
        set cdc_group [dict get $ports_by_direction $io_direction]
        set ports [dict get $cdc_group ports]

        dict set bitfield internal_name [get_hls_portname [dict get $bitfield name]]; # rewrite internal signal names to ensure that reserved keywords aren't used
        dict set bitfield width $bitfield_width
        dict set bitfield io_direction $io_direction
        dict set bitfield access_type $access_type
        lappend ports $bitfield

        dict set cdc_group num_bits [expr [dict get $cdc_group num_bits] + $bitfield_width]
        dict set cdc_group ports $ports
        dict set ports_by_direction $io_direction $cdc_group
        dict set ports_by_domain_and_direction $bitfield_domain $ports_by_direction
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