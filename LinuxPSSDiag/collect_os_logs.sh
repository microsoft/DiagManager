#!/bin/bash

#collect SQL errorlogs
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`
mkdir -p $PWD/output
outputdir=$PWD/output

echo "Collecting dmesg log, journalctl, system logs..."
dmesg > $outputdir/${HOSTNAME}_dmesg.txt
journalctl | tail -n1000 > $outputdir/${HOSTNAME}_journalctl.tail.txt
journalctl -u mssql-server > $outputdir/${HOSTNAME}_journalctl.sql.txt


# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
linuxdistro=`sudo cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

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
