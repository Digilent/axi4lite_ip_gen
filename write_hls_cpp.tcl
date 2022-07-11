# calling context must set the following:
# set specfile_path ${script_dir}/tpl/example.json

set script_dir [file dirname [file normalize [info script]]]
source ${script_dir}/util.tcl

set tplfile_path ${script_dir}/tpl/hls_module.cpp.tpl

#script has no calling context, so set up data for testing
package require json

# load json data
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

set ip_name [dict get $specdata ip_name]
set outfile_path ${script_dir}/intermediates/${ip_name}/${ip_name}.cpp

# set up vars if necessary
set modified_specdata $specdata
set modified_registers [list]
foreach register [dict get $specdata registers] {
    set modified_register $register
    set modified_bitfields [list]
    set access_type [dict get $register access_type]
    if {$access_type == "ro"} {
        set io_direction "in"
    } else {
        set io_direction "out"
    }
    dict set modified_register io_direction $io_direction
    set register_width 0
    foreach bitfield [dict get $register bitfields] {
        set modified_bitfield $bitfield
        # copy io direction into bitfield
        dict set modified_bitfield io_direction $io_direction
        # compute bus width
        set width [expr [dict get $bitfield high_bit] - [dict get $bitfield low_bit] + 1]
        set register_width [expr $register_width + $width]
        dict set modified_bitfield width $width
        lappend modified_bitfields $modified_bitfield
    }
    dict set modified_register width $register_width
    dict set modified_register bitfields $modified_bitfields
    lappend modified_registers $modified_register
}
dict set modified_specdata registers $modified_registers
set specdata $modified_specdata

set address_info [get_register_addresses $specdata]

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