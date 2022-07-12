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

set intermediate_sw_dir ${script_dir}/intermediates/${ip_name}/sw
if {[file exists $intermediate_sw_dir] == 0} {file mkdir $intermediate_sw_dir}
set hwheader_path ${intermediate_sw_dir}/${ip_name}_hw.h
set makefile_path ${intermediate_sw_dir}/Makefile
set hwheader_tpl_path ${script_dir}/tpl/driver_hw.h.tpl
set makefile_tpl_path ${script_dir}/tpl/Makefile.tpl

# set up vars if necessary

# write the driver header
set hwheader [open $hwheader_tpl_path r]
set tmpl [read $hwheader]
close $hwheader

set out [list]
eval [substify $tmpl out]

set f [open $hwheader_path w]
puts $f $out
close $f

# read in the makefile text, replace the substring <XXXX> with the IP name, then write it out
set f [open $makefile_tpl_path r]
set data [read $f]
close $f

set data [string map "<XXXX> ${ip_name}" $data]

set f [open $makefile_path w]
puts $f $data
close $f

# write the MDD file
set mdd [open $mdd_tpl_path r]
set tmpl [read $mdd]
close $mdd

set out [list]
eval [substify $tmpl out]

set f [open $mdd_path w]
puts $f $out
close $f
