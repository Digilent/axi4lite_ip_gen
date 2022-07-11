#! bash
# $1=./examples/ExampleIp.json

filename=$(basename $1)

vitis_hls -f write_hls_ip.tcl $1
sh ./intermediates/${filename%.*}/unzip.sh
vivado -mode batch -source ./package_ip.tcl -tclargs $1 $2