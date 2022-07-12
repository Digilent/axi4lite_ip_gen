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

set driver_name ${ip_name}_v1_0

set intermediate_sw_dir ${script_dir}/intermediates/${ip_name}/sw
if {[file exists $intermediate_sw_dir] == 0} {file mkdir $intermediate_sw_dir}
if {[file exists ${intermediate_sw_dir}/${driver_name}] == 0} {file mkdir ${intermediate_sw_dir}/${driver_name}}
foreach subdir {src data} {
    if {[file exists ${intermediate_sw_dir}/${driver_name}/${subdir}] == 0} {file mkdir ${intermediate_sw_dir}/${driver_name}/${subdir}}
}

set sources [list]

set newsource [dict create]
set hwheader_path ${intermediate_sw_dir}/${driver_name}/src/${ip_name}_hw.h; # used by driver.h.tpl
dict set newsource filepath $hwheader_path
dict set newsource template ${script_dir}/tpl/driver_hw.h.tpl
dict set newsource type "tpl"
lappend sources $newsource


set newsource [dict create]
dict set newsource filepath ${intermediate_sw_dir}/${driver_name}/src/Makefile
dict set newsource template ${script_dir}/tpl/Makefile.tpl
dict set newsource type "xmlish"
lappend sources $newsource

set newsource [dict create]
dict set newsource filepath ${intermediate_sw_dir}/${driver_name}/src/${ip_name}.c
dict set newsource template ${script_dir}/tpl/driver.c.tpl
dict set newsource type "tpl"
lappend sources $newsource

set newsource [dict create]
dict set newsource filepath ${intermediate_sw_dir}/${driver_name}/src/${ip_name}.h
dict set newsource template ${script_dir}/tpl/driver.h.tpl
dict set newsource type "tpl"
lappend sources $newsource

set newsource [dict create]
dict set newsource filepath ${intermediate_sw_dir}/${driver_name}/data/${ip_name}.mdd
dict set newsource template ${script_dir}/tpl/driver_mdd.tpl
dict set newsource type "tpl"
lappend sources $newsource

set newsource [dict create]
dict set newsource filepath ${intermediate_sw_dir}/${driver_name}/data/${ip_name}.tcl
dict set newsource template ${script_dir}/tpl/driver_xpar.tcl.tpl
dict set newsource type "xmlish"
lappend sources $newsource

# grab path to final IP
set component_path [get_files */component.xml]
set ip_path [file dirname $component_path]

# wipe out default driver files but leave the driectories in place
foreach subdir {src data} {
    foreach file [glob -nocomplain ${ip_path}/drivers/${driver_name}/${subdir}/*] {
        ipx::remove_file $file [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
        file delete $file
    }
}

set xmlish_map "<XXXX> ${ip_name} <ip_name> ${ip_name} <interface> ${interface_name}"
foreach srcfile $sources {
    set f [open [dict get $srcfile template] r]
    set template_data [read $f]
    close $f
    if {[dict get $srcfile type] == "tpl"} {
        set output_data [list]
        eval [substify $template_data output_data]
    } elseif {[dict get $srcfile type] == "xmlish"} {
        set output_data [string map $xmlish_map $template_data]
    }
    set f [open [dict get $srcfile filepath] w]
    puts $f $output_data
    close $f
}

# add the generated files to the IP
set file_group xilinx_softwaredriver
foreach subdir {data src} {
    foreach source_file [glob ${intermediate_sw_dir}/${driver_name}/${subdir}/*] {
        add_files -norecurse -copy_to ${ip_path}/drivers/${driver_name}/${subdir} ${source_file}
        ipx::add_file ${ip_path}/drivers/${driver_name}/${subdir}/[file tail $source_file] [ipx::get_file_groups $file_group -of_objects [ipx::current_core]]
    }
}