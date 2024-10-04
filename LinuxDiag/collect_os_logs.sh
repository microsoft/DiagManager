#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

#Starting the script
echo "$(date -u +"%T %D") Starting os logs collection..." | tee -a $pssdiag_log

#collect SQL errorlogs
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`
mkdir -p $PWD/output
outputdir=$PWD/output

#get service manager type

#Check if I am running on host/systemd
if (echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
	echo "$(date -u +"%T %D") Collecting dmesg log, journalctl, system logs..." | tee -a $pssdiag_log
	dmesg > $outputdir/${HOSTNAME}_os_dmesg.out
	journalctl | tail -n1000 > $outputdir/${HOSTNAME}_os.journalctl.out
	journalctl -u mssql-server > $outputdir/${HOSTNAME}_host_instance_journalctl.out
	journalctl -u docker > $outputdir/${HOSTNAME}_os_docker.journalctl.out
	journalctl -u podman > $outputdir/${HOSTNAME}_os_podman.journalctl.out

	# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
	linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

	# Tar command zips all log files specified, to add any other log files add to end of the command.
	case $linuxdistro in
	"ubuntu" | "debian")
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/syslog* $2/kern* $2/auth*.* $2/dpkg* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;
	
	"rhel" | "centos")
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/message* $2/cron* $2/secure* $2/kdump* $2/boot.log $2/yum* $2/dnf* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;

	"sles" | "suse" )
		sh -c 'tar -cjf "$0/$3_os_syslogs_$1.tar.bz2" $2/message* $2/cron* $2/secure* $2/kdump* $2/warn* $2/boot.log $2/zypper* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
		;;
	*) ;;

	esac
fi

get_servicemanager_and_sqlservicestatus "host_instance"

#supporting the case when PSSDiag run from within Kubernetes container
if [[ "${servicemanager}" == "supervisord" ]]; then
	echo -e "$(date -u +"%T %D") Collecting Supervisor, provisioner, agent logs..." | tee -a $pssdiag_log
	
	dmesg > $outputdir/${HOSTNAME}_dmesg.out

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

