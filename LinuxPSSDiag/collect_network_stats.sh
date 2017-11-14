#!/bin/bash
OS_COUNTERS_INTERVAL=$1

working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

sar -n DEV $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_network_stats.perf &
printf "%s\n" "$!" >> $working_dir/stoppids_os_collectors.txt






