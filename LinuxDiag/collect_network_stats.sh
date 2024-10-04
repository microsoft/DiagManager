#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

#if inside container exit 0 
pssdiag_inside_container_get_instance_status
if [ "${is_instance_inside_container_active}" == "YES" ]; then
    exit 0
fi


OS_COUNTERS_INTERVAL=$1

working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

sar -n DEV $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_os_network_stats.perf &
printf "%s\n" "$!" >> $outputdir/pssdiag_stoppids_os_collectors.txt






