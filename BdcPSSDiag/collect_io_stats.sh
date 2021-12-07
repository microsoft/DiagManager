#!/bin/bash
OS_COUNTERS_INTERVAL=$1

working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output

iostat -d $OS_COUNTERS_INTERVAL -k -t -x -y > $outputdir/${HOSTNAME}_iostat.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt


iotop -d $OS_COUNTERS_INTERVAL -k -t -P -o > $outputdir/${HOSTNAME}_iotop.perf &
printf "%s\n" "$!" >> $outputdir/stoppids_os_collectors.txt


