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
if [ "$EUID" -eq 0 ]; then
  ORIGINAL_USERNAME=$(logname)
  ORIGINAL_GROUP=$(id -gn "$ORIGINAL_USERNAME")
  chown "$ORIGINAL_USERNAME:$ORIGINAL_GROUP" "$outputdir" -R
else
	chown $(id -u):$(id -g) "$outputdir" -R
fi

LC_TIME=en_US.UTF-8 iostat -d $OS_COUNTERS_INTERVAL -k -t -x -y > $outputdir/${HOSTNAME}_os_iostat.perf &
printf "%s\n" "$!" >> $outputdir/pssdiag_stoppids_os_collectors.log

if [[ "$EUID" -eq 0 ]]; then
        LC_TIME=en_US.UTF-8 iotop -d $OS_COUNTERS_INTERVAL -k -t -P -o > $outputdir/${HOSTNAME}_os_iotop.perf &
        printf "%s\n" "$!" >> $outputdir/pssdiag_stoppids_os_collectors.log
fi

exit 0

