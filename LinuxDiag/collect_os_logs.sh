#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

#Starting the script
logger "Starting host OS logs collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

#collect SQL errorlogs
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

#get service manager type

#Check if I am running on host/systemd
if (echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
	logger "Collecting dmesg log, journalctl, system logs" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

	# Collect dmesg and journalctl logs only if we run with sudo
	if [ "$EUID" -eq 0 ]; then
		dmesg > $outputdir/${HOSTNAME}_os_dmesg.info 2>/dev/null 
		journalctl | tail -n1000 > $outputdir/${HOSTNAME}_os.journalctl.info 2>/dev/null 
		journalctl -u mssql-server > $outputdir/${HOSTNAME}_host_instance_journalctl.info 2>/dev/null 
		journalctl -u docker > $outputdir/${HOSTNAME}_os_docker.journalctl.info 2>/dev/null 
		journalctl -u podman > $outputdir/${HOSTNAME}_os_podman.journalctl.info 2>/dev/null 
	fi

	# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
	linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

	# Tar command zips all log files specified, to add any other log files add to end of the command.
	case $linuxdistro in
	"ubuntu" | "debian")
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/syslog* $2/sysstat/* $2/kern* $2/auth*.* $2/dpkg* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;
	
	"rhel" | "centos")
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/message* $2/sa/* $2/cron* $2/secure* $2/kdump* $2/boot.log $2/yum* $2/dnf* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;

	"sles" | "suse" )
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/message* $2/sa/* $2/cron* $2/secure* $2/kdump* $2/warn* $2/boot.log $2/zypper* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;
	*) ;;

	esac
fi

get_servicemanager_and_sqlservicestatus "host_instance"

#supporting the case when PSSDiag run from within Kubernetes container
if [[ "${servicemanager}" == "supervisord" ]]; then
	logger "Collecting dmesg log, Supervisor, provisioner, agent logs" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	
	dmesg > $outputdir/${HOSTNAME}_dmesg.info

	# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
	linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

	# Tar command zips all log files specified, to add any other log files add to end of the command.
	case $linuxdistro in
	"ubuntu" | "debian")
		sh -c 'tar -cjf "$0/$3_os_varlogs_$1.tar.bz2" $2/* --ignore-failed-read --absolute-names' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;

	"rhel" | "centos")
		sh -c 'tar -cjf "$0/$3_os_varlogs_$1.tar.bz2" $2/* --ignore-failed-read --absolute-names' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"

		;;
	*) ;;
	
	esac
fi

exit 0