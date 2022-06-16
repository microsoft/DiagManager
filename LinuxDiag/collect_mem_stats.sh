#!/bin/bash
OS_COUNTERS_INTERVAL=$1

working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

#date >> $outputdir/${HOSTNAME}_memory_free.out
#free -k -l -t -s $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_memory_free.out &

sar -r $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_memory_free.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt

sar -S $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_memory_swap.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt


