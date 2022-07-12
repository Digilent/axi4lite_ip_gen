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
set mdd_path ${intermediate_sw_dir}/${ip_name}.mdd
set xpar_tcl_path ${intermediate_sw_dir}/${ip_name}.tcl
set hwheader_tpl_path ${script_dir}/tpl/driver_header.tpl
set makefile_tpl_path ${script_dir}/tpl/Makefile.tpl
set mdd_tpl_path ${script_dir}/tpl/driver_mdd.tpl
set xpar_tcl_tpl_path ${script_dir}/tpl/driver_xpar.tcl.tpl

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

# write the driver tcl file
set f [open $xpar_tcl_tpl_path r]
set data [read $f]
close $f

set interface [dict get $specdata axi4lite_interface]
set interface_name [dict get $interface name]
set data [string map "<ip_name> ${ip_name}" $data]
set data [string map "<interface> ${interface_name}" $data]

set f [open $xpar_tcl_path w]
puts $f $data
close $f

# FIXME add templates for ${ip_name}.h or ${ip_name}.c that don't overwrite version controlled stuff

# add the generated files to the IP
set to_group xilinx_softwaredriver
add_files -norecurse -copy_to ${ip_path}/drivers/src ${hwheader_path}
add_files -norecurse -copy_to ${ip_path}/drivers/src ${makefile_path}
add_files -norecurse -copy_to ${ip_path}/drivers/data ${mdd_path}
add_files -norecurse -copy_to ${ip_path}/drivers/data ${xpar_tcl_path}
ipx::add_file ${ip_path}/drivers/src/[file tail $hwheader_path] [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]
ipx::add_file ${ip_path}/drivers/src/[file tail $makefile_path] [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]
ipx::add_file ${ip_path}/drivers/data/[file tail $mdd_path] [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]
ipx::add_file ${ip_path}/drivers/data/[file tail $xpar_tcl_path] [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]