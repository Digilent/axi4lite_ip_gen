#! vivado TCL console
package require json

set script_dir [file dirname [file normalize [info script]]]

# Read the JSON input file
set specfile_path [file join ${script_dir} "tpl" "example_register_spec.json"]
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

# Iterate over JSON fields for demonstration purposes
foreach interface [dict get $specdata axi4lite_interfaces] {
    puts "[dict get $interface name]"
    puts "  [dict get $interface baseaddr_offset]"
    foreach register [dict get $interface registers] {
        puts "  [dict get $register name]"
        puts "    [dict get $register byte_offset]"
        foreach bitfield [dict get $register bitfields] {
            puts "    [dict get $bitfield name]"
            puts "      [dict get $bitfield high_bit]"
            puts "      [dict get $bitfield low_bit]"
            puts "      [dict get $bitfield access_type]"
            puts "      [dict get $bitfield port]"
            puts "      [dict get $bitfield clock_domain]"
        }
    }
}