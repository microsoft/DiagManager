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
echo -e "$(date -u +"%T %D") Starting os ha log collection..." | tee -a $pssdiag_log

#Execute only if pcs executable is installed
if [ -f /usr/sbin/pcs ];then
	echo -e "$(date -u +"%T %D") Collecting pcs status, Resource etc..."  | tee -a $pssdiag_log
	
	#collect cluster logs
	SYSLOGPATH=/var/log
	NOW=`date +"%m_%d_%Y"`
	mkdir -p $PWD/output
	outputdir=$PWD/output

	infolog_filename=$outputdir/${HOSTNAME}_os_pcs.info
	capture_pcs_status_info

	echo -e "$(date -u +"%T %D") Collecting pacemaker logs..." | tee -a $pssdiag_log

	sh -c 'tar -cjvf "$0/$3_os_pcs_cluster_logs_$1.tar.bz2" $2/pacemaker.log $2/cluster/* $2/pcsd/* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
else
	echo -e "$(date -u +"%T %D") looks pcs is not installed or not in a known path, skipping collecting ha os logs..."  | tee -a $pssdiag_log
fi

