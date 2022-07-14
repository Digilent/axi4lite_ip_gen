#! bash
# $1=./ip_repo

ARG0=$(realpath $0)

for specfile in $(dirname $ARG0)/specifications/*; do
    sh $(dirname $ARG0)/make_ip.sh $specfile $1
done
