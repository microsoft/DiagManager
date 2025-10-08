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
if [ "$EUID" -eq 0 ]; then
  ORIGINAL_USERNAME=$(logname)
  ORIGINAL_GROUP=$(id -gn "$ORIGINAL_USERNAME")
  chown "$ORIGINAL_USERNAME:$ORIGINAL_GROUP" "$outputdir" -R
else
	chown $(id -u):$(id -g) "$outputdir" -R
fi



LC_TIME=en_US.UTF-8 mpstat -P ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2=""; print $0}' > $outputdir/${HOSTNAME}_os_mpstats_cpu.perf &
printf "%s\n" "$!" >> $working_dir/pssdiag_stoppids_os_collectors.log

LC_TIME=en_US.UTF-8 mpstat -I ALL $OS_COUNTERS_INTERVAL | awk 'BEGIN{cmd="date  +\"%m/%d/%y %H:%M:%S\""} {cmd|getline D; close(cmd);if($1 = $'\r') $1=D; else $1="" ; $2="" ; print $0}' > $outputdir/${HOSTNAME}_os_mpstats_interrupt.perf &
printf "%s\n" "$!" >> $working_dir/pssdiag_stoppids_os_collectors.log

exit 0


