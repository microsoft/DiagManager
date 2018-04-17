#!/bin/bash
#Syntax:
#    machineconfig.sh  


# capture_system_info_command()
#
# Capture system information from a command
#
# Arguments:
#   1. Title
#   2. Command
#
function capture_system_info_command()
{
    title=$1
    command=$2

    echo "=== $title ===" >> $infolog_filename
    eval "$2 2>&1" >> $infolog_filename
    echo "" >> $infolog_filename
}


function capture_system_info()
{
    # Capture basic system information
    #
    capture_system_info_command "Uptime" "uptime"
    capture_system_info_command "Kernel Version" "uname -srvimp"
    capture_system_info_command "OS release" "cat /etc/os-release"
    capture_system_info_command "Processor Information" "lscpu"
    capture_system_info_command "Processor Mapping Information" "lscpu -e"
    capture_system_info_command "Processor topology" "cat /proc/cpuinfo"
    capture_system_info_command "Disk Information" "lsblk -o NAME,MAJ:MIN,FSTYPE,MOUNTPOINT,PARTLABEL,SIZE,ALIGNMENT,PHY-SEC,LOG-SEC,MIN-IO,OPT-IO,ROTA,TYPE,RQ-SIZE,LABEL,MODEL,REV,VENDOR" 
    capture_system_info_command "Disk Space Information" "df -TH"
    capture_system_info_command "Free Memory" "free -m"
    capture_system_info_command "System memory information" "cat /proc/meminfo"
    capture_system_info_command "VMA max count" "cat /proc/sys/vm/max_map_count"
    [ -f /usr/sbin/dpkg ] && capture_system_info_command "System package list" "dpkg -l"
    [ -f /usr/bin/yum ] && capture_system_info_command "System package list" "yum list installed"
    capture_system_info_command "Driver List" "lsmod"
    capture_system_info_command "Netowk IP configuration" "ifconfig -a"

}

function capture_process_info()
{
    capture_system_info_command "Command line" "cat /proc/$pid/cmdline"
    capture_system_info_command "VMA count" "cat /proc/$pid/maps | wc -l"
    capture_system_info_command "Process limits" "cat /proc/$pid/limits"
    capture_system_info_command "Process mounts" "cat /proc/$pid/mountinfo"
    capture_system_info_command "Process statistics" "cat /proc/$pid/stat"
    capture_system_info_command "Process status" "cat /proc/$pid/status"
    capture_system_info_command "Process memory maps" "cat /proc/$pid/maps"
    capture_system_info_command "Process memory maps (detailed)" "cat /proc/$pid/smaps"
    capture_system_info_command "Process CGroup information" "cat /proc/$pid/cgroup"
    capture_system_info_command "Process scheduler information" "cat /proc/$pid/sched"
    capture_system_info_command "Process handle information" "hash lsof && lsof -p $pid -O -o"
    capture_system_info_command "Process environment variables" "cat /proc/$pid/environ | tr '\0' '\n' | grep -v 'PASSWORD'"
}


if [[ -d "$1" ]] ; then
	output_dir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   output_dir="$working_dir/output"
fi

infolog_filename=$output_dir/${HOSTNAME}_machineconfig.info
echo "Collecting Machine configuration..."

# Capture basic system information
capture_system_info
ps -efaHjf >> $output_dir/${HOSTNAME}_processlist.info

# loop through each sql process and get its process information
if pgrep -x "sqlservr" > /dev/null 2>&1
then
	for pid in $(pgrep 'sqlservr'); do
		echo "Collecting sqlservr process configuration... PID = ${pid}"
		capture_process_info
	done
else
	echo "No sqlservr process present to collect information..."
fi





