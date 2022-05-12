#!/bin/bash
OS_COUNTERS_INTERVAL=$1


working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

mpstat -P ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2=""; print $0}' > $outputdir/${HOSTNAME}_mpstats_cpu.perf &
printf "%s\n" "$!" >> $working_dir/stoppids_os_collectors.txt

mpstat -I ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2="" ; print $0}' > $outputdir/${HOSTNAME}_mpstats_interrupt.perf &
printf "%s\n" "$!" >> $working_dir/stoppids_os_collectors.txt


