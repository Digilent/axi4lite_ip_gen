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
    puts "  [dict get $interface clock_domain]"
}
foreach register [dict get $specdata registers] {
    puts "  [dict get $register name]"
    puts "    [dict get $register byte_offset]"
    puts "    [dict get $register of_interface]"
    foreach bitfield [dict get $register bitfields] {
        puts "    [dict get $bitfield name]"
        puts "      [dict get $bitfield high_bit]"
        puts "      [dict get $bitfield low_bit]"
        puts "      [dict get $bitfield access_type]"
        puts "      [dict get $bitfield port]"
        puts "      [dict get $bitfield clock_domain]"
    }
}

# # Set up IPX context
set name "TriggerControlAxiAdapter"
set repo [file normalize "D:/Experimental/eclypse-z7-fpga-pfm/hw/proj/../ip_repo"]; # fixme
set vendor "digilent.com"
set version "1.0"
set major_version [lindex [split $version "."] 0]
set minor_version [lindex [split $version "."] 1]
set vlnv "${vendor}:user:${name}:$version"

# Create the IP definition
create_peripheral $vendor user $name $version -dir $repo

foreach interface [dict get $specdata "axi4lite_interfaces"] {
    set interface_name [dict get $interface "name"]

    set num_regs 0
    foreach register [dict get $specdata "registers"] {
        if {[dict get $register "of_interface"] == $interface_name} {
            incr num_regs
        }
    }
    puts "[dict get $interface name]: $num_regs"

    add_peripheral_interface [dict get $interface name] -interface_mode slave -axi_type lite [ipx::find_open_core $vlnv]
    set_property VALUE $num_regs [ipx::get_bus_parameters WIZ_NUM_REG -of_objects [ipx::get_bus_interfaces  -of_objects [ipx::find_open_core $vlnv]]]
}

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
set directory [file join $script_dir "proj"]
ipx::edit_ip_in_project -upgrade true -name edit_${name}_v1_0 -directory ${directory} ${repo}/${name}_${version}/component.xml
update_compile_order -fileset sources_1

# Do some Identification stuff (most is already done)
set_property company_url $vendor [ipx::current_core]

# Set Compatibility

# Do stuff in File Groups
## Wipe out everything in the IP src directory

## Get the IP directory
set component_path [get_files */component.xml]
set ip_path [file dirname $component_path]

## Write top-level HDL file
set top_file_path [file join $ip_path src ${name}_v${major_version}_${minor_version}.v]

## Write CDC HDL file
set cdc_file_path [file join $ip_path src ${name}_cdc.vhd]

# Import HLS-exported sources

# Add Customization Parameters

# Add Ports and Interfaces

# Define Addressing and Memory

# Package the IP and close the project