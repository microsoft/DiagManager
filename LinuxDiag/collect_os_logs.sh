#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

#collect SQL errorlogs
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`
mkdir -p $PWD/output
outputdir=$PWD/output

#get service manager type
get_servicemanager_and_sqlservicestatus "host_instance"

if [[ "${servicemanager}" == "systemd" ]]; then

	echo "Collecting dmesg log, journalctl, system logs..."
	dmesg > $outputdir/${HOSTNAME}_dmesg.txt
	journalctl | tail -n1000 > $output_dir/${HOSTNAME}_journalctl.tail.txt
	journalctl -u mssql-server > $output_dir/${HOSTNAME}_journalctl.sql.txt


	# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
	linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

	# Tar command zips all log files specified, to add any other log files add to end of the command.
	case $linuxdistro in
	"ubuntu" | "debian")
		sh -c 'tar -cjvf "$0/$3_syslogs_$1.tar.bz2" $2/syslog* $2/kern* $2/auth*.*' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;
	
	"rhel" | "centos")
		sh -c 'tar -cjvf "$0/$3_syslogs_$1.tar.bz2" $2/message* $2/cron* $2/secure* $2/boot.log $2/yum.log' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
	
		;;
	*) ;;

	esac
fi

if [[ "${servicemanager}" == "supervisord" ]]; then
	echo "Collecting Supervisor, provisioner, agent logs..."
	
	dmesg > $outputdir/${HOSTNAME}_dmesg.txt

	# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
	linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

	# Tar command zips all log files specified, to add any other log files add to end of the command.
	case $linuxdistro in
	"ubuntu" | "debian")
		sh -c 'tar -cjvf "$0/$3_varlogs_$1.tar.bz2" $2' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;

	"rhel" | "centos")
		sh -c 'tar -cjvf "$0/$3_varlogs_$1.tar.bz2" $2' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"

		;;
	*) ;;
	
	esac
fi	
