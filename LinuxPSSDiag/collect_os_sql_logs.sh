#!/bin/bash

#collect SQL errorlogs
LOGPATH=/var/opt/mssql/log
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`

mkdir -p $PWD/output
outputdir=$PWD/output


echo "Collecting dmesg log, journalctl..."
dmesg > $outputdir/dmesg.txt
journalctl | tail -n1000 > $output_dir/${HOSTNAME}_journalctl.tail.txt
journalctl -u mssql-server > $output_dir/${HOSTNAME}_journalctl.sql.txt


# this is required to figure out version of distro so that System log files are collected appropriately in the following case statement
linuxdistro=`cat /etc/*-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}'`

#collect system logs -- Sudo is due to bug will not need it after fix
sudo sh -c 'cd $2 && tar  -cjvf "$0/sqllogs_$1.tar.bz2" errorlog* *.xel log*.trc' "$outputdir" "$NOW" "$LOGPATH"
#sudo sh -c 'tar  -cjvf "$0/sqllogs_$1.tar.gz" $2/errorlog* $2/*.xel $2/log*.trc*' "$outputdir" "$NOW" "$LOGPATH"

#echo "Linux Distribution: $linuxdistro"

# Tar command zips all log files specified, to add any other log files add to end of the command.
case $linuxdistro in
   "ubuntu" | "debian")
	sudo sh -c 'tar -cjvf "$0/syslogs_$1.tar.bz2" $2/syslog* $2/kern* $2/auth*.*' "$outputdir" "$NOW" "$SYSLOGPATH"
	;;

  "\"rhel\"" | "centos")
	sudo sh -c 'tar -cjvf "$0/syslogs_$1.tar.bz2" $2/message* $2/cron* $2/secure* $2/boot.log $2/yum.log' "$outputdir" "$NOW" "$SYSLOGPATH"

       ;;
 *) ;;

esac
