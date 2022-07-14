#! bash
# $1=./examples/ExampleIp.json
# $2=./ip_repo

ARG0=$(realpath $0)
ARG1=$(realpath $1)
ARG2=$(realpath $2)
FILENAME=$(basename $ARG1)
INTERMEDIATES=$(dirname $ARG0)/intermediates/${FILENAME%.*}
LOGDIR=$(dirname $ARG0)/logs

# cd into (script)/logs, creating it if it doesn't exist
[[ ! -d $LOGDIR ]] && mkdir $LOGDIR
echo "changing directory to $LOGDIR"
pushd $LOGDIR &> /dev/null

# wipe out contents of the intermediates directory for this ip, and create it if it doesn't exist
[[ -d $INTERMEDIATES ]] && rm -rf $INTERMEDIATES/*
[[ ! -d $INTERMEDIATES ]] && mkdir $INTERMEDIATES

vitis_hls -f ../write_hls_ip.tcl $ARG1
sh $INTERMEDIATES/unzip.sh
vivado -mode batch -source ../package_ip.tcl -notrace -tclargs $ARG1 $ARG2

echo "Finished packaging IP -${FILENAME%.*}-"

# return to starting dir
echo "returning to original working dir"
popd &> /dev/null
