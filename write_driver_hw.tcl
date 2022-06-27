# calling context must set this:
# set specfile_path ${script_dir}/examples/ExampleIp.json

set script_dir [file dirname [file normalize [info script]]]
source ${script_dir}/util.tcl

set outfile_path ${script_dir}/intermediates/driver_hw.h
set tplfile_path ${script_dir}/tpl/driver_hw.h.tpl

#script has no calling context, so set up data for testing
package require json

source [file join $script_dir util.tcl]

# load json data
set specfile [open $specfile_path r]
set specdata_json [read $specfile]
close $specfile
set specdata [::json::json2dict $specdata_json]

# set up vars if necessary

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