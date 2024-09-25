#!/bin/bash
OS_COUNTERS_INTERVAL=$1

# include helper functions
source ./pssdiag_support_functions.sh

#if inside container exit 0 
pssdiag_inside_container_get_instance_status
if [ "${is_instance_inside_container_active}" == "YES" ]; then
    exit 0
fi

working_dir="$PWD"
mkdir -p $PWD/output
outputdir=$PWD/output



mpstat -P ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2=""; print $0}' > $outputdir/${HOSTNAME}_os_mpstats_cpu.perf &
printf "%s\n" "$!" >> $working_dir/pssdiag_stoppids_os_collectors.txt

mpstat -I ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2="" ; print $0}' > $outputdir/${HOSTNAME}_os_mpstats_interrupt.perf &
printf "%s\n" "$!" >> $working_dir/pssdiag_stoppids_os_collectors.txt


