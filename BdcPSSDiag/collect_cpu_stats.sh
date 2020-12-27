#!/bin/bash
OS_COUNTERS_INTERVAL=$1


working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

mpstat -P ALL $OS_COUNTERS_INTERVAL > $outputdir/${HOSTNAME}_mpstats_cpu.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt

mpstat -I ALL $OS_COUNTERS_INTERVAL > $outputdir/${HOSTNAME}_mpstats_interrupt.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt


