#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh


# Arguments:
#   1. Title
#   2. Command
#
# function capture_system_info_command()
# {
#     title=$1
#     command=$2

#     echo "=== $title ===" >> $infolog_filename 
#     eval "$2 2>&1" >> $infolog_filename
#     echo "" >> $infolog_filename
# }

function capture_pcs_status_info()
{
	capture_system_info_command "pcs status" "pcs status"
	capture_system_info_command "pcs cluster status" "pcs cluster status"
	capture_system_info_command "pcs resource show –full" "pcs resource show –full"
	capture_system_info_command "pcs cluster cib" "pcs cluster cib"
}

#Starting the script
logger "Starting host HA logs collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

#Execute only if pcs executable is installed
if [ -f /usr/sbin/pcs ];then
	logger "Collecting pcs status, Resource etc" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

	#collect cluster logs
	SYSLOGPATH=/var/log
	NOW=`date +"%m_%d_%Y"`
	mkdir -p $PWD/output
	outputdir=$PWD/output
	if [ "$EUID" -eq 0 ]; then
		group=$(id -gn "$SUDO_USER")
		chown "$SUDO_USER:$group" "$outputdir" -R
	else
		chown $(id -u):$(id -g) "$outputdir" -R
	fi

	infolog_filename=$outputdir/${HOSTNAME}_os_pcs.info
	capture_pcs_status_info

	logger "Collecting pacemaker logs" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

	sh -c 'tar -cjvf "$0/$3_os_pcs_cluster_logs_$1.tar.bz2" $2/pacemaker.log $2/cluster/* $2/pcsd/* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
else
	logger "looks pcs is not installed or not in a known path, skipping collecting host HA logs" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
fi

exit 0