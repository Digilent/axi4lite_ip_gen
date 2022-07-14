# calling context must set this:
# set specfile_path ${script_dir}/tpl/ExampleIp.json

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
set outfile_path ${script_dir}/intermediates/${ip_name}/${ip_name}_cdc.xdc

# set up data for the template to use
set out {
    # Disable timing analysis for clock domain crossing dedicated modules
    set_false_path -through [get_pins -filter {NAME =~ *SyncAsync*/oSyncStages_reg[*]/D} -hier]
    set_false_path -through [get_pins -filter {NAME =~ *SyncAsync*/oSyncStages*/PRE || NAME =~ *SyncAsync*/oSyncStages*/CLR} -hier]

    set_false_path -through [get_pins -filter {NAME =~ *InstHandshake*/*/CLR} -hier]
    set_false_path -from [get_cells -hier -filter {NAME =~ *InstHandshake*/iData_int_reg[*]}] -to [get_cells -hier -filter {NAME=~ *InstHandshake*/oData_reg[*]}]
    
    # are async_regs needed?
}

set f [open $outfile_path w]
puts $f $out
close $f