#!/bin/bash

OS_COUNTERS_INTERVAL=$1
working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

date >> $outputdir/${HOSTNAME}_process_pidstat.perf

pidstat -d -h -I -u -w -r $OS_COUNTERS_INTERVAL >> $outputdir/${HOSTNAME}_process_pidstat.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt

