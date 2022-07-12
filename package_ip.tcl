#! vivado TCL console

# calling context must set these:
# set specfile_path ${script_dir}/examples/ExampleIp.json
# set repo .../vivado-library
set specfile_path [lindex $argv 0]
set repo [lindex $argv 1]

package require json

set script_dir [file dirname [file normalize [info script]]]
source $script_dir/util.tcl

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
set num_regs [get_num_words_in_address_space $specdata]
add_peripheral_interface [dict get $interface name] -interface_mode slave -axi_type lite [ipx::find_open_core $vlnv]
set_property VALUE $num_regs [ipx::get_bus_parameters WIZ_NUM_REG -of_objects [ipx::get_bus_interfaces  -of_objects [ipx::find_open_core $vlnv]]]

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
set ipx_proj edit_${name}_v1_0
ipx::edit_ip_in_project -upgrade true -name $ipx_proj -directory ${directory} ${repo}/${name}_${version}/component.xml
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
### wipe out existing files
ipx::remove_file drivers/TriggerControl_v1_0/src/* [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
ipx::remove_file drivers/TriggerControl_v1_0/data/* [ipx::get_file_groups xilinx_softwaredriver -of_objects [ipx::current_core]]
### generate intermediates and add them to the IP
source [file join $script_dir write_driver_hw.tcl]

# Wipe out existing HDL files and import generated ones
remove_files [get_files -filter name=~${ip_path}/hdl/*]

# Switch file groups to be language-agnostic
ipx::remove_file_group xilinx_verilogsynthesis [ipx::current_core]
ipx::remove_file_group xilinx_verilogbehavioralsimulation [ipx::current_core]
ipx::add_file_group -type synthesis {} [ipx::current_core]
ipx::add_file_group -type simulation {} [ipx::current_core]
set synthesis_group xilinx_anylanguagesynthesis
set sim_group xilinx_anylanguagebehavioralsimulation
set_property model_name ${ip_name}_top [ipx::get_file_groups $synthesis_group]
set_property model_name ${ip_name}_top [ipx::get_file_groups $sim_group]

proc import_hdl_file {filepath to_group} {
    global ip_path
    set filename [file tail $filepath]
    add_files -norecurse -copy_to ${ip_path}/hdl ${filepath}
    ipx::add_file ${ip_path}/hdl/${filename} [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]
    set_property type vhdlSource [ipx::get_files hdl/${filename} -of_objects [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]]
    set_property library_name xil_defaultlib [ipx::get_files hdl/${filename} -of_objects [ipx::get_file_groups $to_group -of_objects [ipx::current_core]]]
}

foreach filepath [glob ${script_dir}/intermediates/${ip_name}/*.vhd] {
    import_hdl_file $filepath $synthesis_group
}

foreach filepath [glob ${script_dir}/src/*.vhd] {
    import_hdl_file $filepath $synthesis_group
}

set_property top ${ip_name}_top [current_fileset]

# Add Customization Parameters

# Adjust Ports and Interfaces
## merge changes before doing anything, to ensure tcl objects are synced
ipx::merge_project_changes ports [ipx::current_core]
## test for the reset port, if it doesn't exit, create it
set reset_name [dict get $interface reset]
set rst_obj [ipx::get_bus_interfaces $reset_name -of_objects [ipx::current_core]]
if {$rst_obj == ""} {
    ipx::add_bus_interface $reset_name [ipx::current_core]
    set rst_obj [ipx::get_bus_interfaces $reset_name -of_objects [ipx::current_core]]
    set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 $rst_obj
    set_property bus_type_vlnv xilinx.com:signal:reset:1.0 $rst_obj
    set_property display_name $reset_name $rst_obj
    ipx::add_bus_parameter POLARITY $rst_obj
    set_property value ACTIVE_LOW [ipx::get_bus_parameters POLARITY -of_objects $rst_obj]
    ipx::add_port_map RST $rst_obj
    set_property physical_name $reset_name [ipx::get_port_maps RST -of_objects $rst_obj]
}
ipx::add_port_map RST [ipx::get_bus_interfaces ${reset_name} -of_objects [ipx::current_core]]
set_property physical_name [dict get $interface reset] [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces ${reset_name} -of_objects [ipx::current_core]]]

## set default drive level of all ports to 0 (FIXME)
foreach register [dict get $specdata registers] {
	foreach bitfield [dict get $register bitfields] {
		set prefix [get_prefix $specdata [dict get $bitfield clock_domain]]
        set ip_port [ipx::get_ports ${prefix}[dict get $bitfield name] -of_objects [ipx::current_core]]
		set_property driver_value 0 $ip_port
	}
}

## add clock parameters and associate them with interfaces and resets as necessary
set_property ipi_drc {ignore_freq_hz true} [ipx::current_core]

foreach clock [dict get $specdata clocks] {
    set clock_name [dict get $clock name]
    puts "Configuring clock $clock_name"

    set clk_obj [ipx::get_bus_interfaces $clock_name -of_objects [ipx::current_core]]
    if {$clk_obj == ""} {
        # the clock is missing, create it
        ipx::add_bus_interface $clock_name [ipx::current_core]
        set clk_obj [ipx::get_bus_interfaces $clock_name -of_objects [ipx::current_core]]
        set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 $clk_obj
        set_property bus_type_vlnv xilinx.com:signal:clock:1.0 $clk_obj
        set_property display_name $clock_name $clk_obj
        ipx::add_bus_parameter FREQ_HZ $clk_obj
        ipx::add_port_map CLK $clk_obj
        set_property physical_name $clock_name [ipx::get_port_maps CLK -of_objects $clk_obj]
    }
}

set axi_rst [dict get [dict get $specdata axi4lite_interface] reset]
set axi_intf_name [dict get [dict get $specdata axi4lite_interface] name]
set axi_clk [dict get [dict get $specdata axi4lite_interface] clock_domain]
set axi_clk_intf [ipx::get_bus_interfaces $axi_clk -of_objects [ipx::current_core]]
ipx::add_bus_parameter ASSOCIATED_RESET $axi_clk_intf
set_property value $axi_rst [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects $axi_clk_intf]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces $axi_clk -of_objects [ipx::current_core]]
set_property value $axi_intf_name [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects $axi_clk_intf]
# FIXME: do the other ports need to be associated with their clocks?

# Define Addressing and Memory

# Package the IP and close the project
ipx::merge_project_changes ports [ipx::current_core]
ipx::merge_project_changes files [ipx::current_core]
ipx::merge_project_changes hdl_parameters [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

set_property core_revision 2 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
puts "Packaged ip [ipx::current_core]"

close_project; # -delete isn't used. -force in create_project overrides the need for it, and the project is preserved for debugging purposes
update_ip_catalog -rebuild -repo_path $repo

