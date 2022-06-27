#! vivado TCL console

# calling context must set these:
# set specfile_path ${script_dir}/examples/ExampleIp.json
# set repo .../vivado-library
set specfile_path [lindex $argv 0]
set repo [lindex $argv 1]

package require json

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir util.tcl]

# Read the JSON input file
set templates_dir [file join ${script_dir} "tpl"]
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

# # Set up IPX context
set name [dict get $specdata ip_name]

set vendor [dict get $specdata vendor]
set version [dict get $specdata version]
set major_version [lindex [split $version "."] 0]
set minor_version [lindex [split $version "."] 1]
set vlnv "${vendor}:user:${name}:$version"

# Create a dummy project
create_project -force container $script_dir/proj -part [dict get $specdata fpga_part]

# Create the IP definition
create_peripheral $vendor user $name $version -dir $repo

set interface [dict get $specdata axi4lite_interface]
set interface_name [dict get $interface name]
set num_regs [expr [dict get $interface reserved_addresses] + [llength [dict get $specdata registers]]]
add_peripheral_interface [dict get $interface name] -interface_mode slave -axi_type lite [ipx::find_open_core $vlnv]
set_property VALUE $num_regs [ipx::get_bus_parameters WIZ_NUM_REG -of_objects [ipx::get_bus_interfaces  -of_objects [ipx::find_open_core $vlnv]]]
## find addr_width


generate_peripheral -force -driver -bfm_example_design -debug_hw_example_design [ipx::find_open_core $vlnv]
write_peripheral [ipx::find_open_core $vlnv]

# If the IP output repo isn't in the project's repo paths, add it
set ip_repo_paths [get_property ip_repo_paths [current_project]]
if {[lsearch $ip_repo_paths $repo] == -1} {
    lappend ip_repo_paths $repo
    set_property ip_repo_paths $ip_repo_paths [current_project]
}

update_ip_catalog -rebuild

# Open a temporary IPX project in the repo directory
set directory $script_dir/ipx_proj
ipx::edit_ip_in_project -upgrade true -name edit_${name}_v1_0 -directory ${directory} ${repo}/${name}_${version}/component.xml
update_compile_order -fileset sources_1

# Do some Identification stuff (most is already done)
set_property company_url https://$vendor [ipx::current_core]

# Set Compatibility

# Do stuff in File Groups
## Wipe out everything in the IP src directory

## Get the IP directory
set component_path [get_files */component.xml]
set ip_path [file dirname $component_path]

## Write top-level HDL file
set top_file_path [file join $ip_path src ${name}_v${major_version}_${minor_version}.v]

## Write CDC HDL file
source [file join $script_dir write_top_vhd.tcl]

## Write software drivers
source [file join $script_dir write_driver_hw.tcl]

# Wipe out existing HDL files and import generated ones
remove_files [get_files -filter name=~${ip_path}/hdl/*]

proc import_hdl_file {filepath} {
    global ip_path
    set filename [file tail $filepath]
    add_files -norecurse -copy_to ${ip_path}/hdl ${filepath}
    ipx::add_file ${ip_path}/hdl/${filename} [ipx::get_file_groups xilinx_verilogsynthesis -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files hdl/${filename} -of_objects [ipx::get_file_groups xilinx_verilogsynthesis -of_objects [ipx::current_core]]]
    set_property library_name xil_defaultlib [ipx::get_files hdl/${filename} -of_objects [ipx::get_file_groups xilinx_verilogsynthesis -of_objects [ipx::current_core]]]
}

foreach filepath [glob ${script_dir}/src/*] {
    import_hdl_file $filepath
}
import_hdl_file ${script_dir}/intermediates/${ip_name}.vhd
import_hdl_file ${script_dir}/intermediates/${ip_name}_top.vhd
set_property top ${ip_name}_top [current_fileset]
ipx::merge_project_changes files [ipx::current_core]

# Add Customization Parameters

# Add Ports and Interfaces

# Define Addressing and Memory

# Package the IP and close the project