#! vitis_hls
set script_dir [file dirname [file normalize [info script]]]

set specfile_path ${script_dir}/tpl/example.json

#script has no calling context, so set up data for testing
package require json

source [file join $script_dir util.tcl]

# load json data
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

set outfile_path ${script_dir}/intermediates/[dict get $specdata ip_name].cpp

# Create the C++ intermediate
source ${script_dir}/write_hls_cpp.tcl

# ------------------------------------------------------------------------------
# Vitis HLS Project Information
# ------------------------------------------------------------------------------
set PROJ_DIR ${script_dir}/tmp
set SOURCE_DIR ${script_dir}/src
set PROJ_NAME "ws"
set PROJ_TOP [dict get $specdata ip_name]
set SOLUTION_NAME "sol1"
set SOLUTION_PART [dict get $specdata fpga_part]
set SOLUTION_CLKP [dict get $specdata target_clk_period]
# MAJOR.MINOR.REVISION
set VERSION "[dict get $specdata version].0"
set DISPLAY_NAME [dict get $specdata ip_name]
set DESCRIPTION "..."
set VENDOR [dict get $specdata vendor]

# ------------------------------------------------------------------------------
# Create Project
# ------------------------------------------------------------------------------
open_project -reset $PROJ_NAME

# ------------------------------------------------------------------------------
# Add C++ source and Testbench files
# ------------------------------------------------------------------------------
add_files ${outfile_path}

# ------------------------------------------------------------------------------
# Create Project and Solution
# ------------------------------------------------------------------------------
set_top $PROJ_TOP
open_solution -reset $SOLUTION_NAME
set_part $SOLUTION_PART
create_clock -period $SOLUTION_CLKP

# ------------------------------------------------------------------------------
# Run Vitis HLS Stages
# ------------------------------------------------------------------------------
csynth_design
# cosim_design -wave_debug -trace_level all
export_design -rtl verilog -format ip_catalog -version $VERSION -description $DESCRIPTION -vendor $VENDOR -display_name $DISPLAY_NAME -output "${script_dir}/intermediates/${PROJ_TOP}.zip"

# -----------------------------------------------------------------------------
# Open project in GUI
# -----------------------------------------------------------------------------
# vitis_hls -p $PROJ_NAME

